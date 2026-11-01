import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:tflite_flutter/tflite_flutter.dart';

const plantDiseaseModelAssetPath = 'assets/models/plant_disease_38.tflite';

// The training notebook feeds RGB image_dataset_from_directory batches
// directly to the model, without rescaling pixel values.
const PlantDiseaseInputScaling plantDiseaseInputScaling =
    PlantDiseaseInputScaling.rawRgb;

enum PlantDiseaseInputScaling { rawRgb, zeroToOne }

class PlantDiseaseMlException implements Exception {
  final String message;

  const PlantDiseaseMlException(this.message);

  @override
  String toString() => message;
}

class PlantDiseaseModelLoadException extends PlantDiseaseMlException {
  const PlantDiseaseModelLoadException(super.message);
}

class PlantDiseasePreprocessingNotConfiguredException
    extends PlantDiseaseMlException {
  const PlantDiseasePreprocessingNotConfiguredException()
    : super(
        'The 38-class model is disabled until its input scaling is verified.',
      );
}

class PlantDiseaseInferenceException extends PlantDiseaseMlException {
  const PlantDiseaseInferenceException(super.message);
}

class PlantDiseasePrediction {
  final int predictedIndex;
  final List<double> scores;

  PlantDiseasePrediction({
    required this.predictedIndex,
    required List<double> scores,
  }) : scores = List.unmodifiable(scores);

  /// Exact source class name for the winning output index.
  String get className =>
      PlantDiseaseMlService.classNameForIndex(predictedIndex);

  /// User-facing form of the source class name; [className] remains unchanged.
  String get displayLabel =>
      PlantDiseaseMlService.displayLabelForClassName(className);

  List<PlantDiseaseClassScore> get topFive {
    final rankedIndexes = List<int>.generate(scores.length, (index) => index)
      ..sort((left, right) {
        final byScore = scores[right].compareTo(scores[left]);
        return byScore != 0 ? byScore : left.compareTo(right);
      });
    return List.unmodifiable(
      rankedIndexes
          .take(5)
          .map(
            (index) => PlantDiseaseClassScore(
              index: index,
              className: PlantDiseaseMlService.classNameForIndex(index),
              displayLabel: PlantDiseaseMlService.displayLabelForClassName(
                PlantDiseaseMlService.classNameForIndex(index),
              ),
              score: scores[index],
            ),
          ),
    );
  }
}

class PlantDiseaseClassScore {
  final int index;
  final String className;
  final String displayLabel;
  final double score;

  const PlantDiseaseClassScore({
    required this.index,
    required this.className,
    required this.displayLabel,
    required this.score,
  });
}

abstract interface class PlantDiseaseInterpreter {
  List<int> get inputShape;
  bool get inputIsFloat32;
  List<int> get outputShape;
  bool get outputIsFloat32;

  List<double> run(Float32List input);
  void close();
}

typedef PlantDiseaseInterpreterLoader =
    Future<PlantDiseaseInterpreter> Function();

class PlantDiseaseMlService {
  static const imageSize = 128;
  static const outputCount = 38;
  static const inputShape = [1, imageSize, imageSize, 3];
  static const outputShape = [1, outputCount];

  /// Output-index order recovered from Train_plant_disease.ipynb's
  /// validation_set.class_names and cross-checked against Test_Plant_Disease.ipynb.
  /// The referenced notebooks are not included in this repository for rechecking.
  static const List<String> classNames = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy',
  ];

  static String classNameForIndex(int index) {
    if (index < 0 || index >= classNames.length) {
      throw RangeError.index(index, classNames, 'index');
    }
    return classNames[index];
  }

  static String displayLabelForClassName(String className) {
    final parts = className.split('___');
    if (parts.length != 2) {
      throw ArgumentError.value(className, 'className', 'Unknown class name');
    }
    return parts
        .map((part) {
          final words = part
              .replaceAll(',_', ', ')
              .replaceAll('_', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
              .toLowerCase();
          return words.replaceAllMapped(
            RegExp(r'(^|[\s(])([a-z])'),
            (match) => '${match[1]}${match[2]!.toUpperCase()}',
          );
        })
        .join(' — ');
  }

  final PlantDiseaseInputScaling? _inputScaling;
  final PlantDiseaseInterpreterLoader _interpreterLoader;

  PlantDiseaseInterpreter? _interpreter;
  Future<PlantDiseaseInterpreter>? _loading;
  bool _disposed = false;

  PlantDiseaseMlService({
    PlantDiseaseInputScaling? inputScaling = plantDiseaseInputScaling,
    PlantDiseaseInterpreterLoader? interpreterLoader,
  }) : _inputScaling = inputScaling,
       _interpreterLoader = interpreterLoader ?? _loadTensorFlowLiteModel;

  Future<PlantDiseasePrediction> predictImagePath(String imagePath) async {
    if (_disposed) {
      throw const PlantDiseaseMlException(
        'The plant disease model service has been disposed.',
      );
    }
    final scaling = _inputScaling;
    if (scaling == null) {
      throw const PlantDiseasePreprocessingNotConfiguredException();
    }

    final bytes = await File(imagePath).readAsBytes();
    final input = await compute(
      _preprocessImageInBackground,
      <Object>[bytes, scaling.index],
      debugLabel: 'plant-disease-image-preprocessing',
    );
    final interpreter = await _loadModel();
    if (_disposed) {
      throw const PlantDiseaseMlException(
        'The plant disease model service has been disposed.',
      );
    }

    try {
      final scores = interpreter.run(input);
      final predictedIndex = predictionIndexForScores(scores);
      return PlantDiseasePrediction(
        predictedIndex: predictedIndex,
        scores: scores,
      );
    } on PlantDiseaseInferenceException {
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        '38-class plant disease inference failed.',
        name: 'PlantDiseaseMlService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const PlantDiseaseInferenceException(
        'Plant disease prediction failed. Please try again.',
      );
    }
  }

  Future<PlantDiseaseInterpreter> _loadModel() {
    final interpreter = _interpreter;
    if (interpreter != null) return Future.value(interpreter);
    return _loading ??= _initializeModel();
  }

  Future<PlantDiseaseInterpreter> _initializeModel() async {
    PlantDiseaseInterpreter? interpreter;
    try {
      interpreter = await _interpreterLoader();
      validateTensorContract(
        inputShape: interpreter.inputShape,
        inputIsFloat32: interpreter.inputIsFloat32,
        outputShape: interpreter.outputShape,
        outputIsFloat32: interpreter.outputIsFloat32,
      );
      if (_disposed) {
        interpreter.close();
        throw const PlantDiseaseMlException(
          'The plant disease model service has been disposed.',
        );
      }
      _interpreter = interpreter;
      return interpreter;
    } catch (error, stackTrace) {
      if (interpreter != null && !identical(interpreter, _interpreter)) {
        interpreter.close();
      }
      _loading = null;
      if (error is PlantDiseaseMlException) rethrow;
      developer.log(
        '38-class plant disease model could not be loaded.',
        name: 'PlantDiseaseMlService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const PlantDiseaseModelLoadException(
        'The 38-class plant disease model could not be loaded.',
      );
    }
  }

  static void validateTensorContract({
    required List<int> inputShape,
    required bool inputIsFloat32,
    required List<int> outputShape,
    required bool outputIsFloat32,
  }) {
    if (PlantDiseaseMlService.classNames.length != outputCount ||
        !listEquals(inputShape, PlantDiseaseMlService.inputShape) ||
        !inputIsFloat32 ||
        !listEquals(outputShape, PlantDiseaseMlService.outputShape) ||
        !outputIsFloat32) {
      throw const PlantDiseaseModelLoadException(
        'The plant disease model has an unexpected tensor shape or type.',
      );
    }
  }

  static int predictionIndexForScores(List<double> scores) {
    if (scores.length != outputCount ||
        scores.any((score) => !score.isFinite)) {
      throw const PlantDiseaseInferenceException(
        'The plant disease model returned invalid scores.',
      );
    }

    var predictedIndex = 0;
    for (var index = 1; index < scores.length; index++) {
      if (scores[index] > scores[predictedIndex]) predictedIndex = index;
    }
    return predictedIndex;
  }

  static Float32List preprocessImageBytes(
    Uint8List bytes, {
    required PlantDiseaseInputScaling scaling,
  }) {
    if (bytes.isEmpty) {
      throw const FormatException(
        'The selected file is not a supported image.',
      );
    }
    final decoded = image.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      throw const FormatException(
        'The selected file is not a supported image.',
      );
    }

    final rgbImage = decoded.convert(
      format: image.Format.uint8,
      numChannels: 3,
    );
    final resized = image.copyResize(
      rgbImage,
      width: imageSize,
      height: imageSize,
      interpolation: image.Interpolation.linear,
    );
    final tensor = Float32List(imageSize * imageSize * 3);
    for (var y = 0; y < imageSize; y++) {
      for (var x = 0; x < imageSize; x++) {
        final pixel = resized.getPixel(x, y);
        final offset = (y * imageSize + x) * 3;
        final divisor = scaling == PlantDiseaseInputScaling.zeroToOne
            ? 255.0
            : 1.0;
        tensor[offset] = pixel.r.toDouble() / divisor;
        tensor[offset + 1] = pixel.g.toDouble() / divisor;
        tensor[offset + 2] = pixel.b.toDouble() / divisor;
      }
    }
    return tensor;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interpreter?.close();
    _interpreter = null;
    _loading = null;
  }

  static Future<PlantDiseaseInterpreter> _loadTensorFlowLiteModel() async {
    final interpreter = await Interpreter.fromAsset(plantDiseaseModelAssetPath);
    return _TensorFlowLiteInterpreter(interpreter);
  }
}

Float32List _preprocessImageInBackground(List<Object> arguments) {
  final bytes = arguments[0];
  final scalingIndex = arguments[1];
  if (bytes is! Uint8List ||
      scalingIndex is! int ||
      scalingIndex < 0 ||
      scalingIndex >= PlantDiseaseInputScaling.values.length) {
    throw const FormatException('Invalid image preprocessing request.');
  }
  return PlantDiseaseMlService.preprocessImageBytes(
    bytes,
    scaling: PlantDiseaseInputScaling.values[scalingIndex],
  );
}

class _TensorFlowLiteInterpreter implements PlantDiseaseInterpreter {
  final Interpreter _interpreter;

  _TensorFlowLiteInterpreter(this._interpreter);

  @override
  List<int> get inputShape => _interpreter.getInputTensor(0).shape;

  @override
  bool get inputIsFloat32 =>
      _interpreter.getInputTensor(0).type == TensorType.float32;

  @override
  List<int> get outputShape => _interpreter.getOutputTensor(0).shape;

  @override
  bool get outputIsFloat32 =>
      _interpreter.getOutputTensor(0).type == TensorType.float32;

  @override
  List<double> run(Float32List input) {
    final inputTensor = _interpreter.getInputTensor(0);
    inputTensor.data = Uint8List.view(
      input.buffer,
      input.offsetInBytes,
      input.lengthInBytes,
    );
    _interpreter.invoke();
    final output = _interpreter.getOutputTensor(0).data;
    return output.buffer
        .asFloat32List(output.offsetInBytes, output.lengthInBytes ~/ 4)
        .toList(growable: false);
  }

  @override
  void close() => _interpreter.close();
}
