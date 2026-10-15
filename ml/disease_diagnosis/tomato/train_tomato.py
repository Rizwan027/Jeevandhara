from __future__ import annotations

import argparse
import csv
import json
import random
from pathlib import Path
import numpy as np
import torch
from PIL import Image
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import GroupShuffleSplit
from torch import nn
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms
from torchvision.models import mobilenet_v3_small


CLASS_NAMES = (
    "Tomato___Bacterial_spot",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy",
)
IMAGE_SIZE = 224
RESIZE_SIZE = 256
IMAGE_MEAN = (0.485, 0.456, 0.406)
IMAGE_STD = (0.229, 0.224, 0.225)
SEED = 42


class TomatoImages(Dataset):
    def __init__(self, rows: list[dict[str, str]], root: Path, training: bool):
        self.rows = rows
        self.root = root
        self.transform = transforms.Compose(
            [
                transforms.Resize(RESIZE_SIZE),
                transforms.CenterCrop(IMAGE_SIZE),
                transforms.RandomHorizontalFlip(p=0.5 if training else 0),
                transforms.ToTensor(),
                transforms.Normalize(IMAGE_MEAN, IMAGE_STD),
            ]
        )

    def __len__(self) -> int:
        return len(self.rows)

    def __getitem__(self, index: int) -> tuple[torch.Tensor, int]:
        row = self.rows[index]
        image_path = self.root / row["image_path"]
        with Image.open(image_path) as image:
            tensor = self.transform(image.convert("RGB"))
        return tensor, CLASS_NAMES.index(row["label"])


def load_manifest(manifest_path: Path, dataset_root: Path) -> list[dict[str, str]]:
    required = {"image_path", "label", "leaf_id", "split"}
    rows: list[dict[str, str]] = []
    with manifest_path.open(newline="", encoding="utf-8") as manifest_file:
        reader = csv.DictReader(manifest_file)
        missing = required.difference(reader.fieldnames or ())
        if missing:
            raise ValueError(f"Manifest is missing columns: {sorted(missing)}")
        for line_number, row in enumerate(reader, start=2):
            label = row["label"].strip()
            leaf_id = row["leaf_id"].strip()
            split = row["split"].strip()
            image_path = Path(row["image_path"])
            if image_path.is_absolute() or ".." in image_path.parts:
                raise ValueError(
                    "Manifest image paths must stay under the dataset root "
                    f"(line {line_number})."
                )
            if not label.startswith("Tomato___") or label not in CLASS_NAMES:
                raise ValueError(
                    "Unsupported PlantVillage tomato label on line "
                    f"{line_number}: {label!r}"
                )
            if not leaf_id or leaf_id.lower() in {"unknown", "none", "nan"}:
                raise ValueError(
                    f"Missing physical-leaf group ID on line {line_number}."
                )
            if split not in {"train", "test"}:
                raise ValueError(
                    "Source split must be 'train' or 'test' "
                    f"(line {line_number})."
                )
            if not (dataset_root / image_path).is_file():
                raise FileNotFoundError(
                    f"Image listed on line {line_number} does not exist: "
                    f"{image_path}"
                )
            rows.append(
                {
                    "image_path": image_path.as_posix(),
                    "label": label,
                    "leaf_id": leaf_id,
                    "split": split,
                }
            )

    if not rows:
        raise ValueError("The manifest contains no Tomato images.")

    leaf_splits: dict[str, set[str]] = {}
    leaf_labels: dict[str, set[str]] = {}
    for row in rows:
        leaf_splits.setdefault(row["leaf_id"], set()).add(row["split"])
        leaf_labels.setdefault(row["leaf_id"], set()).add(row["label"])
    if any(len(splits) > 1 for splits in leaf_splits.values()):
        raise ValueError("A physical leaf occurs in more than one official source split.")
    if any(len(labels) > 1 for labels in leaf_labels.values()):
        raise ValueError("A physical leaf is assigned more than one class label.")

    present = {row["label"] for row in rows}
    if present != set(CLASS_NAMES):
        raise ValueError(
            "Manifest must contain all ten PlantVillage tomato classes; "
            f"missing={sorted(set(CLASS_NAMES) - present)}, unexpected={sorted(present - set(CLASS_NAMES))}"
        )
    if not {"train", "test"}.issubset({row["split"] for row in rows}):
        raise ValueError("Manifest must include the official PlantVillage train and test splits.")
    return rows


def split_rows(rows: list[dict[str, str]]) -> tuple[list[dict[str, str]], ...]:
    source_train = [row for row in rows if row["split"] == "train"]
    source_test = [row for row in rows if row["split"] == "test"]
    groups = np.asarray([row["leaf_id"] for row in source_train])
    indices = np.arange(len(source_train))
    splitter = GroupShuffleSplit(n_splits=1, test_size=0.125, random_state=SEED)
    train_indices, validation_indices = next(
        splitter.split(indices, groups=groups)
    )
    train = [source_train[index] for index in train_indices]
    validation = [source_train[index] for index in validation_indices]
    for name, part in (("train", train), ("validation", validation), ("test", source_test)):
        present = {row["label"] for row in part}
        missing = set(CLASS_NAMES) - present
        if missing:
            raise ValueError(
                f"Grouped {name} split lacks classes "
                f"{sorted(missing)}; "
                "check the source manifest and group distribution."
            )
    group_sets = [
        {row["leaf_id"] for row in part} for part in (train, validation, source_test)
    ]
    if any(
        group_sets[left] & group_sets[right]
        for left, right in ((0, 1), (0, 2), (1, 2))
    ):
        raise ValueError("Physical-leaf groups overlap between dataset splits.")
    return train, validation, source_test


def build_model() -> nn.Module:
    model = mobilenet_v3_small(weights=None)
    final_layer = model.classifier[-1]
    if not isinstance(final_layer, nn.Linear):
        raise RuntimeError("Unexpected MobileNetV3 Small classifier layout.")
    model.classifier[-1] = nn.Linear(final_layer.in_features, len(CLASS_NAMES))
    return model


def load_pretrained_backbone(model: nn.Module, weights_path: Path) -> None:
    if not weights_path.is_file():
        raise FileNotFoundError(
            f"Pretrained weights not found: {weights_path}. "
            "Download the official TorchVision weights manually; this script never downloads weights."
        )
    state = torch.load(weights_path, map_location="cpu", weights_only=True)
    if not isinstance(state, dict) or not all(isinstance(key, str) for key in state):
        raise ValueError(
            "Expected a raw TorchVision MobileNetV3 Small state dictionary."
        )
    model_state = model.state_dict()
    compatible = {
        key: value
        for key, value in state.items()
        if key in model_state and model_state[key].shape == value.shape
    }
    missing, unexpected = model.load_state_dict(compatible, strict=False)
    expected_missing = {
        key for key in model_state if key.startswith("classifier.3.")
    }
    if set(missing) != expected_missing or unexpected:
        raise ValueError(
            "Pretrained weights do not match TorchVision MobileNetV3 Small."
        )
    for parameter in model.features.parameters():
        parameter.requires_grad = False


def evaluate_loss(
    model: nn.Module, loader: DataLoader, device: torch.device
) -> float:
    model.eval()
    loss_function = nn.CrossEntropyLoss()
    total_loss = 0.0
    total_images = 0
    with torch.inference_mode():
        for images, labels in loader:
            images, labels = images.to(device), labels.to(device)
            loss = loss_function(model(images), labels)
            total_loss += loss.item() * labels.size(0)
            total_images += labels.size(0)
    return total_loss / total_images


def train_epoch(
    model: nn.Module, loader: DataLoader, optimizer, device: torch.device
) -> float:
    model.train()
    model.features.eval()
    loss_function = nn.CrossEntropyLoss()
    total_loss = 0.0
    total_images = 0
    for images, labels in loader:
        images, labels = images.to(device), labels.to(device)
        optimizer.zero_grad(set_to_none=True)
        loss = loss_function(model(images), labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item() * labels.size(0)
        total_images += labels.size(0)
    return total_loss / total_images


def export_onnx(model: nn.Module, output_path: Path) -> None:
    model.eval().cpu()
    sample = torch.zeros(1, 3, IMAGE_SIZE, IMAGE_SIZE)
    torch.onnx.export(
        model,
        sample,
        output_path,
        input_names=["images"],
        output_names=["logits"],
        dynamic_axes={"images": {0: "batch"}, "logits": {0: "batch"}},
        opset_version=17,
        do_constant_folding=True,
        dynamo=False,
    )
    import onnx

    onnx.checker.check_model(str(output_path))


def write_test_report(
    model: nn.Module,
    loader: DataLoader,
    device: torch.device,
    output_dir: Path,
) -> None:
    model.eval()
    predictions: list[int] = []
    targets: list[int] = []
    with torch.inference_mode():
        for images, labels in loader:
            logits = model(images.to(device))
            predictions.extend(logits.argmax(dim=1).cpu().tolist())
            targets.extend(labels.tolist())

    report = classification_report(
        targets,
        predictions,
        labels=list(range(len(CLASS_NAMES))),
        target_names=CLASS_NAMES,
        output_dict=True,
        zero_division=0,
    )
    (output_dir / "test_metrics.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    matrix = confusion_matrix(
        targets, predictions, labels=list(range(len(CLASS_NAMES)))
    )
    with (output_dir / "confusion_matrix.csv").open(
        "w", newline="", encoding="utf-8"
    ) as matrix_file:
        writer = csv.writer(matrix_file)
        writer.writerow(["true/predicted", *CLASS_NAMES])
        for class_name, row in zip(CLASS_NAMES, matrix, strict=True):
            writer.writerow([class_name, *row.tolist()])
    print(json.dumps(report, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Train and export a tomato leaf classifier."
    )
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--dataset-root", type=Path, required=True)
    parser.add_argument("--pretrained-weights", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=32)
    args = parser.parse_args()
    if args.epochs < 1 or args.batch_size < 1:
        parser.error("--epochs and --batch-size must be positive.")

    random.seed(SEED)
    np.random.seed(SEED)
    torch.manual_seed(SEED)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(SEED)

    rows = load_manifest(args.manifest, args.dataset_root)
    train_rows, validation_rows, test_rows = split_rows(rows)
    train_transform = TomatoImages(train_rows, args.dataset_root, training=True)
    validation_transform = TomatoImages(
        validation_rows, args.dataset_root, training=False
    )
    test_transform = TomatoImages(test_rows, args.dataset_root, training=False)
    train_loader = DataLoader(
        train_transform, batch_size=args.batch_size, shuffle=True, num_workers=0
    )
    validation_loader = DataLoader(
        validation_transform, batch_size=args.batch_size, shuffle=False, num_workers=0
    )
    test_loader = DataLoader(
        test_transform, batch_size=args.batch_size, shuffle=False, num_workers=0
    )

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = build_model()
    load_pretrained_backbone(model, args.pretrained_weights)
    model.to(device)
    optimizer = torch.optim.AdamW(
        (
            parameter
            for parameter in model.parameters()
            if parameter.requires_grad
        ),
        lr=1e-3,
    )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_path = args.output_dir / "tomato_mobilenet_v3_small.pt"
    best_validation_loss = float("inf")
    for epoch in range(1, args.epochs + 1):
        training_loss = train_epoch(model, train_loader, optimizer, device)
        validation_loss = evaluate_loss(model, validation_loader, device)
        print(
            f"epoch={epoch}/{args.epochs} device={device} "
            f"train_loss={training_loss:.4f} "
            f"validation_loss={validation_loss:.4f}"
        )
        if validation_loss < best_validation_loss:
            best_validation_loss = validation_loss
            torch.save(
                {
                    "architecture": "torchvision.mobilenet_v3_small",
                    "class_names": list(CLASS_NAMES),
                    "image_size": IMAGE_SIZE,
                    "resize_size": RESIZE_SIZE,
                    "mean": IMAGE_MEAN,
                    "std": IMAGE_STD,
                    "state_dict": model.cpu().state_dict(),
                },
                checkpoint_path,
            )
            model.to(device)

    checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=True)
    model.load_state_dict(checkpoint["state_dict"])
    model.to(device)
    write_test_report(model, test_loader, device, args.output_dir)
    onnx_path = args.output_dir / "tomato_mobilenet_v3_small.onnx"
    export_onnx(model, onnx_path)
    print(f"Checkpoint: {checkpoint_path}")
    print(f"ONNX model: {onnx_path}")


if __name__ == "__main__":
    main()
