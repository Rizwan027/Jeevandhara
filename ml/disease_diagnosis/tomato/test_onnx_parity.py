from pathlib import Path

import numpy as np
import pytest
import torch
import onnxruntime as ort

from train_tomato import CLASS_NAMES, build_model


ARTIFACT_DIR = Path(__file__).parent / "artifacts"
CHECKPOINT_PATH = ARTIFACT_DIR / "tomato_mobilenet_v3_small.pt"
ONNX_PATH = ARTIFACT_DIR / "tomato_mobilenet_v3_small.onnx"


def test_torch_and_onnx_runtime_outputs_match() -> None:
    checkpoint_exists = CHECKPOINT_PATH.is_file()
    onnx_exists = ONNX_PATH.is_file()
    if not checkpoint_exists and not onnx_exists:
        pytest.skip("Training artifacts have not been generated.")
    if not checkpoint_exists:
        pytest.fail(f"Missing PyTorch checkpoint: {CHECKPOINT_PATH}")
    if not onnx_exists:
        pytest.fail(f"Missing ONNX model: {ONNX_PATH}")

    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=True)
    assert checkpoint["class_names"] == list(CLASS_NAMES)

    model = build_model()
    model.load_state_dict(checkpoint["state_dict"])
    model.eval()
    generator = torch.Generator().manual_seed(42)
    sample = torch.randn((1, 3, checkpoint["image_size"], checkpoint["image_size"]), generator=generator)

    with torch.inference_mode():
        torch_output = model(sample).numpy()
    session = ort.InferenceSession(str(ONNX_PATH), providers=["CPUExecutionProvider"])
    onnx_output = session.run(["logits"], {"images": sample.numpy()})[0]

    np.testing.assert_allclose(onnx_output, torch_output, rtol=1e-4, atol=1e-5)
