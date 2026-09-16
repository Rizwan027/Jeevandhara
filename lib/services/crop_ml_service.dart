import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

const cropMlFeatureNames = <String>[
  'N',
  'P',
  'K',
  'temperature',
  'humidity',
  'ph',
];

const cropMlClassNames = <String>[
  'apple',
  'banana',
  'blackgram',
  'chickpea',
  'coconut',
  'coffee',
  'cotton',
  'grapes',
  'jute',
  'kidneybeans',
  'lentil',
  'maize',
  'mango',
  'mothbeans',
  'mungbean',
  'muskmelon',
  'orange',
  'papaya',
  'pigeonpeas',
  'pomegranate',
  'rice',
  'watermelon',
];

class CropMlException implements Exception {
  final String message;

  const CropMlException(this.message);

  @override
  String toString() => message;
}

class CropPrediction {
  final String crop;
  final double confidence;
  final List<CropProbability> topCrops;

  const CropPrediction({
    required this.crop,
    required this.confidence,
    required this.topCrops,
  });
}

class CropProbability {
  final String crop;
  final double probability;

  const CropProbability({required this.crop, required this.probability});
}

abstract interface class CropMlPredictor {
  Future<CropPrediction> predict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
  });
}

class CropMlService implements CropMlPredictor {
  static const _modelAssetPath =
      'ml/output/crop_model_6feature_compatible.onnx';
  static const _modelInputName = 'features';
  static const _expectedClassCount = 22;

  OrtSession? _session;
  Future<void>? _loading;

  Future<void> _loadModel() {
    return _loading ??= _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      OrtEnv.instance.init();
      final data = await rootBundle.load(_modelAssetPath);
      final modelBytes = Uint8List.view(
        data.buffer,
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
      sessionOptions.release();
    } catch (_) {
      _loading = null;
      throw const CropMlException(
        'The crop prediction model could not be loaded.',
      );
    }
  }

  @override
  Future<CropPrediction> predict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
  }) async {
    if (![
      nitrogen,
      phosphorus,
      potassium,
      temperature,
      humidity,
      ph,
    ].every((value) => value.isFinite)) {
      throw const CropMlException('Crop prediction inputs must be finite.');
    }

    try {
      await _loadModel();
      final session = _session;
      if (session == null) {
        throw const CropMlException(
          'The crop prediction model is unavailable.',
        );
      }

      final input = OrtValueTensor.createTensorWithDataList(
        [
          Float32List.fromList([
            nitrogen,
            phosphorus,
            potassium,
            temperature,
            humidity,
            ph,
          ]),
        ],
        [1, cropMlFeatureNames.length],
      );
      final runOptions = OrtRunOptions();
      final outputs =
          await session.runAsync(runOptions, {_modelInputName: input}) ??
          const <OrtValue?>[];

      try {
        return _parseOutputs(outputs);
      } finally {
        input.release();
        runOptions.release();
        for (final output in outputs) {
          output?.release();
        }
      }
    } on CropMlException {
      rethrow;
    } catch (_) {
      throw const CropMlException(
        'Crop prediction failed. Please try again later.',
      );
    }
  }

  CropPrediction _parseOutputs(List<OrtValue?> outputs) {
    if (outputs.length < 2 || outputs[0] == null || outputs[1] == null) {
      throw const CropMlException(
        'The crop model returned an invalid response.',
      );
    }

    final labels = (outputs[0]! as OrtValueTensor).value as List<dynamic>;
    final probabilities =
        (outputs[1]! as OrtValueTensor).value as List<List<dynamic>>;
    if (labels.length != 1 || probabilities.length != 1) {
      throw const CropMlException(
        'The crop model returned an invalid response.',
      );
    }

    final probabilityRow = probabilities.single
        .map((value) => (value as num).toDouble())
        .toList();
    if (probabilityRow.length != _expectedClassCount || labels.single == null) {
      throw const CropMlException(
        'The crop model returned an invalid response.',
      );
    }

    final predictedCrop = labels.single.toString();
    final ranked = [
      for (var index = 0; index < probabilityRow.length; index++)
        CropProbability(
          crop: cropMlClassNames[index],
          probability: probabilityRow[index],
        ),
    ];
    ranked.sort((a, b) => b.probability.compareTo(a.probability));
    return CropPrediction(
      crop: predictedCrop,
      confidence: ranked.first.probability,
      topCrops: ranked.take(3).toList(growable: false),
    );
  }

  void dispose() {
    _session?.release();
    _session = null;
    _loading = null;
  }
}
