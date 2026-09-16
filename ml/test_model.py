from pathlib import Path

import joblib
import pandas as pd


FEATURES = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]
MODEL_PATH = Path(__file__).parent / "output" / "crop_model.joblib"

SAMPLES = [
    {
        "N": 90,
        "P": 42,
        "K": 43,
        "temperature": 20.88,
        "humidity": 82.00,
        "ph": 6.50,
        "rainfall": 202.94,
    },
    {
        "N": 60,
        "P": 40,
        "K": 40,
        "temperature": 25.0,
        "humidity": 80.0,
        "ph": 6.5,
        "rainfall": 100.0,
    },
    {
        "N": 100,
        "P": 20,
        "K": 50,
        "temperature": 22.0,
        "humidity": 60.0,
        "ph": 6.8,
        "rainfall": 120.0,
    },
    {
        "N": 20,
        "P": 130,
        "K": 200,
        "temperature": 28.0,
        "humidity": 85.0,
        "ph": 6.2,
        "rainfall": 220.0,
    },
    {
        "N": 10,
        "P": 10,
        "K": 10,
        "temperature": 18.0,
        "humidity": 65.0,
        "ph": 7.0,
        "rainfall": 50.0,
    },
]


def main() -> None:
    if not MODEL_PATH.is_file():
        raise FileNotFoundError(f"Model not found: {MODEL_PATH}")

    model = joblib.load(MODEL_PATH)
    samples = pd.DataFrame(SAMPLES, columns=FEATURES)
    predictions = model.predict(samples)
    probabilities = model.predict_proba(samples)
    classes = list(model.classes_)

    for index, (sample, prediction, probability_row) in enumerate(
        zip(SAMPLES, predictions, probabilities), start=1
    ):
        ranked = sorted(
            zip(classes, probability_row), key=lambda item: item[1], reverse=True
        )
        print(f"Sample {index}")
        print(f"Input values: {sample}")
        print(f"Predicted crop: {prediction}")
        print(f"Prediction confidence: {probability_row[classes.index(prediction)]:.4f}")
        print("Top 3 predictions:")
        for crop, probability in ranked[:3]:
            print(f"  {crop}: {probability:.4f}")
        print()


if __name__ == "__main__":
    main()
