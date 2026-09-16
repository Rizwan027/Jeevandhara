from pathlib import Path

import joblib
import numpy as np
import pandas as pd


FEATURES = ["N", "P", "K", "temperature", "humidity", "ph"]
MODEL_PATH = Path(__file__).parent / "output" / "crop_model_6feature.joblib"
SAMPLES = [
    [90.0, 42.0, 43.0, 20.88, 82.0, 6.5],
    [60.0, 40.0, 40.0, 25.0, 80.0, 6.5],
    [100.0, 20.0, 50.0, 22.0, 60.0, 6.8],
    [20.0, 130.0, 200.0, 28.0, 85.0, 6.2],
    [10.0, 10.0, 10.0, 18.0, 65.0, 7.0],
]


def main() -> None:
    if not MODEL_PATH.is_file():
        raise FileNotFoundError(f"Model not found: {MODEL_PATH}")

    model = joblib.load(MODEL_PATH)
    if list(model.feature_names_in_) != FEATURES:
        raise ValueError(f"Unexpected feature order: {list(model.feature_names_in_)}")

    inputs = pd.DataFrame(SAMPLES, columns=FEATURES)
    probabilities = model.predict_proba(inputs)
    predictions = model.predict(inputs)
    classes = list(model.classes_)

    print(f"Feature order: {', '.join(FEATURES)}")
    print(f"Model: {type(model).__name__}")
    print()
    for index, (sample, prediction, row) in enumerate(
        zip(SAMPLES, predictions, probabilities), start=1
    ):
        if not np.isfinite(row).all() or (row < 0).any():
            raise ValueError(f"Invalid probability values for sample {index}")
        probability_sum = float(row.sum())
        if not np.isclose(probability_sum, 1.0, atol=1e-6):
            raise ValueError(
                f"Probabilities for sample {index} sum to {probability_sum:.8f}"
            )

        ranked = sorted(
            zip(classes, row), key=lambda item: item[1], reverse=True
        )[:3]
        print(f"Sample {index}")
        print(f"Input values: {sample}")
        print(f"Top-3 predictions (probability sum: {probability_sum:.8f}):")
        for crop, probability in ranked:
            print(f"  {crop}: {probability:.6f}")
        print(f"Final predicted crop: {prediction}")
        print()


if __name__ == "__main__":
    main()
