import warnings
from pathlib import Path

import joblib
import numpy as np
import onnx
import onnxruntime as ort
import pandas as pd
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType


FEATURES = ["N", "P", "K", "temperature", "humidity", "ph"]
MODEL_PATH = Path(__file__).parent / "output" / "crop_model_6feature.joblib"
ONNX_PATH = Path(__file__).parent / "output" / "crop_model_6feature_compatible.onnx"

TEST_INPUTS = np.array(
    [
        [90, 42, 43, 20.88, 82.00, 6.50],
        [60, 40, 40, 25.0, 80.0, 6.5],
        [100, 20, 50, 22.0, 60.0, 6.8],
        [20, 130, 200, 28.0, 85.0, 6.2],
        [10, 10, 10, 18.0, 65.0, 7.0],
    ],
    dtype=np.float32,
)


def _onnx_value_info(value_info: onnx.ValueInfoProto) -> str:
    tensor_type = value_info.type.tensor_type
    shape = [
        dimension.dim_value if dimension.dim_value else "?"
        for dimension in tensor_type.shape.dim
    ]
    return f"shape={shape}, type={onnx.TensorProto.DataType.Name(tensor_type.elem_type)}"


def main() -> None:
    if not MODEL_PATH.is_file():
        raise FileNotFoundError(f"Model not found: {MODEL_PATH}")

    model = joblib.load(MODEL_PATH)
    if list(model.feature_names_in_) != FEATURES:
        raise ValueError(
            "Unexpected model feature order: "
            f"{list(model.feature_names_in_)}; expected {FEATURES}"
        )
    if len(model.classes_) != 22:
        raise ValueError(f"Expected 22 crop classes, found {len(model.classes_)}")

    initial_type = [("features", FloatTensorType([None, len(FEATURES)]))]
    with warnings.catch_warnings(record=True) as conversion_warnings:
        warnings.simplefilter("always")
        onnx_model = convert_sklearn(
            model,
            initial_types=initial_type,
            options={id(model): {"zipmap": False}},
            target_opset=10,
        )

    ONNX_PATH.parent.mkdir(parents=True, exist_ok=True)
    ONNX_PATH.write_bytes(onnx_model.SerializeToString())
    onnx.checker.check_model(onnx_model)

    print(f"ONNX model saved to: {ONNX_PATH}")
    if conversion_warnings:
        print("Conversion warnings:")
        for warning in conversion_warnings:
            print(f"- {warning.message}")
    else:
        print("Conversion warnings: none")

    print("ONNX input:")
    for value_info in onnx_model.graph.input:
        print(f"  {value_info.name}: {_onnx_value_info(value_info)}")
    print("ONNX outputs:")
    for value_info in onnx_model.graph.output:
        print(f"  {value_info.name}: {_onnx_value_info(value_info)}")

    session = ort.InferenceSession(
        str(ONNX_PATH), providers=["CPUExecutionProvider"]
    )
    input_name = session.get_inputs()[0].name
    onnx_outputs = session.run(None, {input_name: TEST_INPUTS})
    onnx_labels = np.asarray(onnx_outputs[0])
    onnx_probabilities = np.asarray(onnx_outputs[1])

    joblib_inputs = pd.DataFrame(TEST_INPUTS, columns=FEATURES)
    joblib_labels = model.predict(joblib_inputs)
    joblib_probabilities = model.predict_proba(joblib_inputs)
    embedded_class_labels = next(
        attribute.strings
        for node in onnx_model.graph.node
        for attribute in node.attribute
        if attribute.name == "classlabels_strings"
    )
    if onnx_probabilities.shape != (len(TEST_INPUTS), 22):
        raise AssertionError("ONNX probability output does not represent all 22 crop classes.")
    onnx_class_labels = [label.decode() for label in embedded_class_labels]
    if onnx_class_labels != [
        str(label) for label in model.classes_
    ]:
        raise AssertionError("ONNX embedded class-label mapping does not match Joblib.")

    matches = []
    print("\nValidation:")
    for index in range(len(TEST_INPUTS)):
        joblib_label = str(joblib_labels[index])
        onnx_label = str(onnx_labels[index])
        joblib_top3 = sorted(
            zip(model.classes_, joblib_probabilities[index]),
            key=lambda item: item[1],
            reverse=True,
        )[:3]
        onnx_top3 = sorted(
            zip(onnx_class_labels, onnx_probabilities[index]),
            key=lambda item: item[1],
            reverse=True,
        )[:3]
        label_match = joblib_label == onnx_label
        top3_match = [str(item[0]) for item in joblib_top3] == [
            str(item[0]) for item in onnx_top3
        ]
        probability_delta = float(
            np.max(np.abs(joblib_probabilities[index] - onnx_probabilities[index]))
        )
        probability_match = probability_delta <= 1e-6
        matches.append(label_match and top3_match and probability_match)
        print(f"Test input {index + 1}: {TEST_INPUTS[index].tolist()}")
        print(f"  joblib top-3: {[(str(crop), float(probability)) for crop, probability in joblib_top3]}")
        print(f"  ONNX top-3:   {[(str(crop), float(probability)) for crop, probability in onnx_top3]}")
        print(f"  predicted crop: joblib={joblib_label}, ONNX={onnx_label}")
        print(f"  max probability delta: {probability_delta:.9g}")
        print(f"  predictions match: {matches[-1]}")

    if not all(matches):
        raise AssertionError("ONNX validation did not match the joblib model.")
    print(f"\nAll {len(matches)} test inputs matched.")


if __name__ == "__main__":
    main()
