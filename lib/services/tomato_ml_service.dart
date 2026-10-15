import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:onnxruntime/onnxruntime.dart';

import '../models/crop_diagnosis_result.dart';
import '../models/tomato_disease_information.dart';

typedef TomatoModelRunner = Future<List<num>> Function(Float32List tensorData);

class TomatoMlService {
  static final TomatoMlService instance = TomatoMlService._();

  static const _modelAssetPath =
      'jeevandhara_tomato_model/tomato_mobilenet_v3_small.onnx';
  static const _inputName = 'images';
  static const _outputName = 'logits';
  static const _imageSize = 224;
  static const _resizeSize = 256;
  @visibleForTesting
  static const tomatoClassNames = <String>[
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___healthy',
  ];
  static const _mean = [0.485, 0.456, 0.406];
  static const _std = [0.229, 0.224, 0.225];

  static bool _environmentInitialized = false;

  Future<OrtSession>? _loading;
  final TomatoModelRunner? _modelRunner;

  TomatoMlService._() : _modelRunner = null;

  @visibleForTesting
  TomatoMlService.forTesting({required TomatoModelRunner modelRunner})
    : _modelRunner = modelRunner;

  Future<Map<String, dynamic>> analyzePlantHealth(String imagePath) async {
    try {
      final tensorData = preprocessImageBytes(
        await File(imagePath).readAsBytes(),
      );
      final logits =
          await (_modelRunner?.call(tensorData) ?? _runModel(tensorData));
      final result = classifyLogits(logits);
      final resultMap = result.toLegacyMap();
      final information = TomatoDiseaseInformation.forName(
        result.diseaseLabel!,
      );
      if (information == null) {
        throw const FormatException('Tomato model class has no information.');
      }
      resultMap
        ..['disease'] = information.name
        ..['status'] =
            'Unverified model prediction — not a confirmed diagnosis.'
        ..['prediction_note'] =
            'Unverified model prediction — not a confirmed diagnosis.';
      if (information.isHealthy) {
        resultMap['healthy_explanation'] = information.possibleCause;
      } else {
        resultMap
          ..['possible_cause'] = information.possibleCause
          ..['recommended_actions'] = information.recommendedActions
          ..['prevention'] = information.prevention;
      }
      return resultMap;
    } catch (error, stackTrace) {
      developer.log(
        'Tomato model analysis failed; returning an unavailable result.',
        name: 'TomatoMlService',
        error: error,
        stackTrace: stackTrace,
      );
      return const CropDiagnosisResult.unavailable().toLegacyMap();
    }
  }

  Future<List<num>> _runModel(Float32List tensorData) async {
    final session = await _loadModel();
    final input = OrtValueTensor.createTensorWithDataList(tensorData, [
      1,
      3,
      _imageSize,
      _imageSize,
    ]);
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;

    try {
      outputs = await session.runAsync(runOptions, {_inputName: input});
      if (outputs == null || outputs.length != 1) {
        throw const FormatException('Invalid tomato model output count.');
      }

      final output = outputs.single;
      if (output is! OrtValueTensor) {
        throw const FormatException('Tomato model output is not a tensor.');
      }
      final value = output.value;
      if (value is! List || value.length != 1 || value.single is! List) {
        throw const FormatException('Invalid tomato model output shape.');
      }

      final row = value.single as List;
      if (row.length != tomatoClassNames.length ||
          row.any((item) => item is! num)) {
        throw const FormatException('Invalid tomato model logits.');
      }
      return row.cast<num>();
    } finally {
      input.release();
      runOptions.release();
      for (final output in outputs ?? const <OrtValue?>[]) {
        output?.release();
      }
    }
  }

  Future<OrtSession> _loadModel() {
    return _loading ??= _initializeModel();
  }

  Future<OrtSession> _initializeModel() async {
    try {
      if (!_environmentInitialized) {
        OrtEnv.instance.init();
        _environmentInitialized = true;
      }

      final data = await rootBundle.load(_modelAssetPath);
      final modelBytes = Uint8List.view(
        data.buffer,
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final options = OrtSessionOptions();
      OrtSession? session;
      try {
        session = OrtSession.fromBuffer(modelBytes, options);
        if (session.inputCount != 1 ||
            session.inputNames.length != 1 ||
            session.inputNames.first != _inputName ||
            session.outputCount != 1 ||
            session.outputNames.length != 1 ||
            session.outputNames.first != _outputName) {
          throw const FormatException(
            'Tomato model input/output names do not match the expected contract.',
          );
        }
        return session;
      } catch (_) {
        session?.release();
        rethrow;
      } finally {
        options.release();
      }
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static CropDiagnosisResult classifyLogits(List<num> logits) {
    if (logits.length != tomatoClassNames.length ||
        logits.any((value) => !value.isFinite)) {
      throw const FormatException('Tomato model returned invalid logits.');
    }

    final modelLabel = tomatoClassNames[_topLogitIndex(logits)];
    final information = TomatoDiseaseInformation.forModelLabel(modelLabel);
    if (information == null) {
      throw const FormatException('Tomato model class has no information.');
    }
    return CropDiagnosisResult.uncertain(
      cropLabel: 'Tomato',
      diseaseLabel: information.name,
    );
  }

  static int _topLogitIndex(List<num> logits) {
    var topIndex = 0;
    for (var index = 1; index < logits.length; index++) {
      if (logits[index] > logits[topIndex]) topIndex = index;
    }
    return topIndex;
  }

  static Float32List preprocessImageBytes(Uint8List bytes) {
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
    final width = rgbImage.width;
    final height = rgbImage.height;
    final resizedWidth = width <= height
        ? _resizeSize
        : (width * _resizeSize / height).floor();
    final resizedHeight = height <= width
        ? _resizeSize
        : (height * _resizeSize / width).floor();
    final resized = image.copyResize(
      rgbImage,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: image.Interpolation.linear,
    );
    final cropped = image.copyCrop(
      resized,
      x: _centerCropOffset(resizedWidth - _imageSize),
      y: _centerCropOffset(resizedHeight - _imageSize),
      width: _imageSize,
      height: _imageSize,
    );

    final planeSize = _imageSize * _imageSize;
    final tensor = Float32List(3 * planeSize);
    for (var y = 0; y < _imageSize; y++) {
      for (var x = 0; x < _imageSize; x++) {
        final pixel = cropped.getPixel(x, y);
        final offset = y * _imageSize + x;
        tensor[offset] = (pixel.r / 255 - _mean[0]) / _std[0];
        tensor[planeSize + offset] = (pixel.g / 255 - _mean[1]) / _std[1];
        tensor[2 * planeSize + offset] = (pixel.b / 255 - _mean[2]) / _std[2];
      }
    }
    return tensor;
  }

  static int _centerCropOffset(int difference) {
    final lower = difference ~/ 2;
    if (difference.isEven || lower.isEven) return lower;
    return lower + 1;
  }
}
