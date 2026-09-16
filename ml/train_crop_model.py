from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import ExtraTreesClassifier, HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, precision_recall_fscore_support
from sklearn.model_selection import GridSearchCV, StratifiedKFold, cross_val_score, train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC


FEATURES = ["N", "P", "K", "temperature", "humidity", "ph"]
TARGET = "label"
DATA_PATH = Path(__file__).parent / "data" / "crop_recommendation.csv"
OUTPUT_DIR = Path(__file__).parent / "output"
MODEL_PATH = OUTPUT_DIR / "crop_model_6feature.joblib"
REPORT_PATH = OUTPUT_DIR / "model_comparison_6feature.txt"
PREVIOUS_SIX_FEATURE_ACCURACY = 0.9682


def load_data() -> tuple[pd.DataFrame, pd.Series]:
    if not DATA_PATH.is_file():
        raise FileNotFoundError(f"Dataset not found: {DATA_PATH}")

    data = pd.read_csv(DATA_PATH)
    required_columns = FEATURES + [TARGET]
    missing_columns = [column for column in required_columns if column not in data]
    if missing_columns:
        raise ValueError(f"Dataset is missing required columns: {missing_columns}")

    data = data[required_columns].copy()
    for feature in FEATURES:
        data[feature] = pd.to_numeric(data[feature], errors="coerce")
    data = data.dropna()
    if data.empty or data[TARGET].nunique() < 2:
        raise ValueError("Dataset must contain complete rows and at least two classes.")
    if not data[FEATURES].map(lambda value: value == value and abs(value) != float("inf")).all().all():
        raise ValueError("Feature values must be finite numbers.")
    return data[FEATURES], data[TARGET]


def evaluate_model(name, model, x_train, x_test, y_train, y_test, folds):
    cv_scores = cross_val_score(model, x_train, y_train, cv=folds, scoring="accuracy", n_jobs=-1)
    model.fit(x_train, y_train)
    predictions = model.predict(x_test)
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_test, predictions, average="weighted", zero_division=0
    )
    return {
        "name": name,
        "model": model,
        "cv_mean": cv_scores.mean(),
        "cv_std": cv_scores.std(),
        "test_accuracy": accuracy_score(y_test, predictions),
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "predictions": predictions,
    }


def main() -> None:
    x, y = load_data()
    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=42, stratify=y
    )
    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

    rf_search = GridSearchCV(
        RandomForestClassifier(random_state=42, n_jobs=-1),
        {
            "n_estimators": [200, 300],
            "max_depth": [None, 20],
            "min_samples_leaf": [1, 2],
            "max_features": ["sqrt", 0.8],
        },
        cv=folds,
        scoring="accuracy",
        n_jobs=-1,
    )
    extra_search = GridSearchCV(
        ExtraTreesClassifier(random_state=42, n_jobs=-1),
        {
            "n_estimators": [200, 300],
            "max_depth": [None, 20],
            "min_samples_leaf": [1, 2],
            "max_features": ["sqrt", 0.8],
        },
        cv=folds,
        scoring="accuracy",
        n_jobs=-1,
    )
    rf_search.fit(x_train, y_train)
    extra_search.fit(x_train, y_train)

    results = [
        evaluate_model("RandomForestClassifier", rf_search.best_estimator_, x_train, x_test, y_train, y_test, folds),
        evaluate_model("ExtraTreesClassifier", extra_search.best_estimator_, x_train, x_test, y_train, y_test, folds),
        evaluate_model(
            "HistGradientBoostingClassifier",
            HistGradientBoostingClassifier(random_state=42),
            x_train, x_test, y_train, y_test, folds,
        ),
        evaluate_model(
            "SVC",
            make_pipeline(StandardScaler(), SVC(C=10, gamma="scale", kernel="rbf")),
            x_train, x_test, y_train, y_test, folds,
        ),
    ]
    best = max(results, key=lambda result: result["cv_mean"])
    class_labels = sorted(y.unique())
    matrix = pd.DataFrame(
        confusion_matrix(y_test, best["predictions"], labels=class_labels),
        index=class_labels,
        columns=class_labels,
    )
    report = [
        "Six-feature crop model experiment",
        f"Dataset size: {len(x)} rows",
        f"Number of classes: {len(class_labels)}",
        f"Features: {', '.join(FEATURES)}",
        "Split: stratified 80/20 train/test, random_state=42",
        "Model selection: Stratified 5-Fold CV on training set only, shuffle=True, random_state=42",
        "Models tested: RandomForestClassifier, ExtraTreesClassifier, HistGradientBoostingClassifier, SVC",
        "",
        "Candidate results:",
    ]
    for result in results:
        report.append(
            f"{result['name']}: CV accuracy {result['cv_mean']:.6f} +/- {result['cv_std']:.6f}; "
            f"test accuracy {result['test_accuracy']:.6f}; precision {result['precision']:.6f}; "
            f"recall {result['recall']:.6f}; F1 {result['f1']:.6f}"
        )
    report.extend([
        "",
        f"Best model: {best['name']}",
        f"Best hyperparameters: {best['model'].get_params()}",
        f"Best CV accuracy mean/std: {best['cv_mean']:.6f} / {best['cv_std']:.6f}",
        f"Final test accuracy: {best['test_accuracy']:.6f}",
        f"Final weighted precision/recall/F1: {best['precision']:.6f} / {best['recall']:.6f} / {best['f1']:.6f}",
        f"Previous six-feature baseline: {PREVIOUS_SIX_FEATURE_ACCURACY:.6f}",
        f"Improved over previous baseline: {best['test_accuracy'] > PREVIOUS_SIX_FEATURE_ACCURACY}",
        "",
        "Final classification report:",
        classification_report(y_test, best["predictions"], labels=class_labels, zero_division=0),
        "Confusion matrix (rows=true, columns=predicted):",
        matrix.to_string(),
    ])
    output = "\n".join(report)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(best["model"], MODEL_PATH)
    REPORT_PATH.write_text(output + "\n", encoding="utf-8")
    print(output)
    print(f"\nSaved model: {MODEL_PATH}")
    print(f"Saved report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
