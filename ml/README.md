# Crop Recommendation Model Training

This folder contains the training setup for a small crop-label classifier. It is designed to run in a free Google Colab environment and does not download or generate a dataset.

## Dataset

Place the dataset at:

```text
ml/data/crop_recommendation.csv
```

The CSV must contain these columns:

```text
nitrogen,phosphorus,potassium,temperature,humidity,ph,label
```

The six feature columns are numeric. `label` is the target crop label.

## Google Colab

From the repository root in a Colab notebook:

```python
!pip install -r ml/requirements.txt
```

Upload or mount the dataset at `ml/data/crop_recommendation.csv`, then run:

```python
!python ml/train_crop_model.py
```

The script prints test accuracy and a classification report, then saves the trained Random Forest classifier to:

```text
ml/output/crop_model.joblib
```

The model expects features in this order:

```text
nitrogen, phosphorus, potassium, temperature, humidity, ph
```
