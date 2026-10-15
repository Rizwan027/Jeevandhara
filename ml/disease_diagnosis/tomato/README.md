# Tomato leaf disease training pipeline

This is a research/training pipeline only. It does not download data or weights,
does not connect to the Flutter scan flow, and does not establish field
diagnostic reliability.

## Dataset and license

Use the **color** configuration of the [PlantVillage dataset](https://huggingface.co/datasets/mohanty/PlantVillage)
by Mohanty, Hughes, and Salathé. The dataset card documents 54,306 images,
`leaf_id` values, and official 80/20 train/test splits grouped so the same leaf
does not appear in both. Hugging Face metadata declares **CC BY-SA 3.0**, but
the dataset builder source describes this license as an assumption that needs
verification, and the original repository does not clearly establish the
underlying image rights. Treat the declaration as unconfirmed: do not
redistribute the dataset or trained weights until provenance and terms are
clarified. If CC BY-SA 3.0 is confirmed, provide attribution, link the license,
and review its share-alike terms for adapted material or trained weights.
The original [paper](https://doi.org/10.3389/fpls.2016.01419) describes images
collected under controlled conditions. Its published result is not evidence of
performance on farm photographs.

Tomato class labels and order follow the dataset's published class metadata:

1. `Tomato___Bacterial_spot`
2. `Tomato___Early_blight`
3. `Tomato___Late_blight`
4. `Tomato___Leaf_Mold`
5. `Tomato___Septoria_leaf_spot`
6. `Tomato___Spider_mites Two-spotted_spider_mite`
7. `Tomato___Target_Spot`
8. `Tomato___Tomato_Yellow_Leaf_Curl_Virus`
9. `Tomato___Tomato_mosaic_virus`
10. `Tomato___healthy`

The labels reflect the source dataset taxonomy, not a guarantee that these
conditions can be reliably distinguished from arbitrary field images.

## Dataset preparation

Use a free Google Colab runtime or local Python environment. Obtain the dataset
manually from the source above; no project script downloads it. Export Tomato
rows from the source's official `train` and `test` splits to local image files
and create a UTF-8 `manifest.csv` with these columns:

```csv
image_path,label,leaf_id,split
images/train/000001.jpg,Tomato___Bacterial_spot,physical-leaf-id,train
images/test/000002.jpg,Tomato___Bacterial_spot,other-physical-leaf-id,test
```

`image_path` must be relative to the dataset root. Preserve the source `label`,
`leaf_id`, and official split values exactly. Keep every image for one leaf in
its source split. The loader rejects missing/unknown group IDs, non-tomato or
unknown labels, cross-split leaf overlap, missing classes, and nonexistent
image paths. A deterministic grouped split takes 12.5% of the official training
partition for validation; the official test partition is reserved for final
reporting.

The following is an explicit, user-run Colab preparation cell. It downloads
the selected dataset through Hugging Face Datasets only when you choose to run
it; neither training nor the test script performs a download. The revision
argument pins the dataset snapshot used by this cell; it does not resolve
dataset licensing or validate performance on field images:

```python
!pip install datasets
from datasets import load_dataset
from pathlib import Path
import csv

root = Path("ml/disease_diagnosis/tomato/data")
root.mkdir(parents=True, exist_ok=True)
dataset = load_dataset(
    "mohanty/PlantVillage",
    "color",
    revision="9e97599868962bd0079b8db4b7f1efa9185fa1e7",
)
with (root / "manifest.csv").open("w", newline="", encoding="utf-8") as output:
    writer = csv.DictWriter(output, fieldnames=["image_path", "label", "leaf_id", "split"])
    writer.writeheader()
    for split in ("train", "test"):
        part = dataset[split]
        for index, row in enumerate(part):
            label = part.features["label"].int2str(row["label"])
            if not label.startswith("Tomato___"):
                continue
            relative_path = Path("images") / split / f"{index:06d}.jpg"
            image_path = root / relative_path
            image_path.parent.mkdir(parents=True, exist_ok=True)
            row["image"].convert("RGB").save(image_path, format="JPEG", quality=95)
            writer.writerow({
                "image_path": relative_path.as_posix(),
                "label": label,
                "leaf_id": row["leaf_id"],
                "split": split,
            })
```

## Setup and training

Install dependencies in the notebook/runtime explicitly; this does not change
the Flutter dependencies:

```bash
python -m pip install torch torchvision pillow numpy scikit-learn onnx onnxruntime pytest
```

Use the official TorchVision
[MobileNetV3 Small ImageNet-1K V1 weights](https://download.pytorch.org/models/mobilenet_v3_small-047dcff4.pth).
Download this file manually to `ml/disease_diagnosis/tomato/pretrained/mobilenet_v3_small-047dcff4.pth`;
the training script requires a local file and never downloads pretrained
weights. TorchVision's pretrained weights are distributed with the
[TorchVision license](https://github.com/pytorch/vision/blob/main/LICENSE).
The dataset and pretrained checkpoint are not part of this repository.

From the repository root in Colab or another Bash shell, run:

```bash
python ml/disease_diagnosis/tomato/train_tomato.py \
  --manifest ml/disease_diagnosis/tomato/data/manifest.csv \
  --dataset-root ml/disease_diagnosis/tomato/data \
  --pretrained-weights ml/disease_diagnosis/tomato/pretrained/mobilenet_v3_small-047dcff4.pth \
  --output-dir ml/disease_diagnosis/tomato/artifacts \
  --epochs 8 --batch-size 32
```

On Windows PowerShell, put the same arguments on one line. CUDA is used when
available; otherwise it trains on CPU. The convolutional feature extractor is frozen for this first transfer
learning baseline, while the classifier head is trained. Validation loss
selects the checkpoint. The official held-out test partition is evaluated
once, with per-class precision/recall/F1 and overall metrics written to
`test_metrics.json`, plus a labelled `confusion_matrix.csv`.

## Preprocessing and ONNX export

The Python preprocessing contract is RGB decode, resize shortest edge to 256
pixels with TorchVision's bilinear `Resize`, center crop to 224x224, convert to
float32 `[0,1]`, then normalize channels using mean
`[0.485, 0.456, 0.406]` and standard deviation
`[0.229, 0.224, 0.225]`. Training additionally applies a random horizontal
flip. Model input is NCHW float32 `[batch,3,224,224]`; output is ten raw logits
in the class order above. The export uses ONNX opset 17 with dynamic batch size.
The script exports and checks
`tomato_mobilenet_v3_small.onnx` after training; no ONNX file is checked in.

Check parity after a real checkpoint and export exist:

```bash
python -m pytest ml/disease_diagnosis/tomato/test_onnx_parity.py -q
```

Without those artifacts the parity test is skipped. Before Flutter integration,
verify the exported graph with the exact pinned `onnxruntime` Flutter plugin on
Android and iOS, compare preprocessing/output parity on representative image
files, and measure latency and memory on target devices. The existing crop
recommendation ONNX model/service is separate and unchanged.

## Before any release

Review source annotations and licensing, then evaluate on independent,
field-collected tomato images split by farm/plant (not just by image). Include
healthy, non-tomato, low-quality, and out-of-scope images; report per-class
metrics, confusion matrix, calibration, and failure cases. PlantVillage's
curated images and its test split cannot establish field reliability. Do not
present a healthy result or diagnosis for unsupported/out-of-distribution
images without separately validated detection and uncertainty behavior.
