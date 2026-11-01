import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:jeevandhara/services/plant_disease_ml_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlantDiseaseMlService', () {
    test('defaults to the training pipeline raw RGB input range', () {
      expect(plantDiseaseInputScaling, PlantDiseaseInputScaling.rawRgb);
      expect(PlantDiseaseMlService.inputShape, [1, 128, 128, 3]);
    });

    test('maps every output index to the source class order', () {
      expect(PlantDiseaseMlService.classNames, [
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
      ]);
      expect(
        PlantDiseaseMlService.classNameForIndex(18),
        'Pepper,_bell___Bacterial_spot',
      );
      expect(
        PlantDiseaseMlService.displayLabelForClassName(
          'Pepper,_bell___Bacterial_spot',
        ),
        'Pepper, Bell — Bacterial Spot',
      );
      expect(
        PlantDiseaseMlService.displayLabelForClassName(
          'Grape___Esca_(Black_Measles)',
        ),
        'Grape — Esca (Black Measles)',
      );
    });

    test('bundled TFLite model asset is available', () async {
      final model = await rootBundle.load(plantDiseaseModelAssetPath);
      final identifier = String.fromCharCodes(
        model.buffer.asUint8List(model.offsetInBytes + 4, 4),
      );

      expect(identifier, 'TFL3');
      expect(model.lengthInBytes, greaterThan(8));
    });

    test('declares and validates float32 NHWC model tensors', () {
      expect(PlantDiseaseMlService.inputShape, [1, 128, 128, 3]);
      expect(PlantDiseaseMlService.outputShape, [1, 38]);
      PlantDiseaseMlService.validateTensorContract(
        inputShape: [1, 128, 128, 3],
        inputIsFloat32: true,
        outputShape: [1, 38],
        outputIsFloat32: true,
      );
      expect(
        () => PlantDiseaseMlService.validateTensorContract(
          inputShape: [1, 3, 128, 128],
          inputIsFloat32: true,
          outputShape: [1, 38],
          outputIsFloat32: true,
        ),
        throwsA(isA<PlantDiseaseModelLoadException>()),
      );
      expect(
        () => PlantDiseaseMlService.validateTensorContract(
          inputShape: [1, 128, 128, 3],
          inputIsFloat32: false,
          outputShape: [1, 38],
          outputIsFloat32: true,
        ),
        throwsA(isA<PlantDiseaseModelLoadException>()),
      );
      expect(
        () => PlantDiseaseMlService.validateTensorContract(
          inputShape: [1, 128, 128, 3],
          inputIsFloat32: true,
          outputShape: [1, 38],
          outputIsFloat32: false,
        ),
        throwsA(isA<PlantDiseaseModelLoadException>()),
      );
    });

    test('resizes to RGB float32 and keeps scaling explicit', () {
      final source = image.Image(width: 2, height: 1, numChannels: 4)
        ..setPixelRgba(0, 0, 255, 12, 1, 0)
        ..setPixelRgba(1, 0, 10, 20, 30, 255);
      final bytes = image.encodePng(source);
      final raw = PlantDiseaseMlService.preprocessImageBytes(
        bytes,
        scaling: PlantDiseaseInputScaling.rawRgb,
      );
      final normalized = PlantDiseaseMlService.preprocessImageBytes(
        bytes,
        scaling: PlantDiseaseInputScaling.zeroToOne,
      );

      expect(raw, isA<Float32List>());
      expect(raw.length, 128 * 128 * 3);
      expect(raw[0], 255);
      expect(raw[1], 12);
      expect(raw[2], 1);
      expect(normalized[0], 1);
      expect(normalized[1], closeTo(12 / 255, 1e-6));
      expect(normalized[2], closeTo(1 / 255, 1e-6));
      expect(
        () => PlantDiseaseMlService.preprocessImageBytes(
          Uint8List.fromList('not an image'.codeUnits),
          scaling: PlantDiseaseInputScaling.rawRgb,
        ),
        throwsFormatException,
      );
    });

    test('returns the top index and all 38 scores', () async {
      final imageFile = await _temporaryImageFile(
        red: 255,
        green: 128,
        blue: 1,
      );
      final fake = _FakeInterpreter(scores: List.generate(38, (i) => i / 37));
      final service = PlantDiseaseMlService(
        interpreterLoader: () async => fake,
      );
      addTearDown(service.dispose);

      final prediction = await service.predictImagePath(imageFile.path);

      expect(prediction.predictedIndex, 37);
      expect(prediction.scores, hasLength(38));
      expect(prediction.className, 'Tomato___healthy');
      expect(prediction.topFive, hasLength(5));
      expect(prediction.topFive.map((entry) => entry.index), [
        37,
        36,
        35,
        34,
        33,
      ]);
      expect(
        prediction.topFive.map((entry) => entry.score),
        orderedEquals(
          prediction.topFive.map((entry) => entry.score).toList()
            ..sort((a, b) => b.compareTo(a)),
        ),
      );
      expect(fake.receivedInput, hasLength(128 * 128 * 3));
      expect(fake.receivedInput!.take(3), [255, 128, 1]);
      expect(
        fake.receivedInput!.length,
        PlantDiseaseMlService.inputShape.reduce((a, b) => a * b),
      );
    });

    test('rejects invalid output sizes, values, and image bytes', () {
      expect(
        () => PlantDiseaseMlService.predictionIndexForScores([0, 1]),
        throwsA(isA<PlantDiseaseInferenceException>()),
      );
      expect(
        () => PlantDiseaseMlService.predictionIndexForScores(
          List<double>.filled(38, 0)..[4] = double.infinity,
        ),
        throwsA(isA<PlantDiseaseInferenceException>()),
      );
      expect(
        () => PlantDiseaseMlService.preprocessImageBytes(
          Uint8List(0),
          scaling: PlantDiseaseInputScaling.rawRgb,
        ),
        throwsFormatException,
      );
    });

    test('allows inference to be explicitly disabled by callers', () async {
      final imageFile = await _temporaryImageFile();
      var loaderCalled = false;
      final service = PlantDiseaseMlService(
        inputScaling: null,
        interpreterLoader: () async {
          loaderCalled = true;
          return _FakeInterpreter(scores: List<double>.filled(38, 0));
        },
      );
      addTearDown(service.dispose);

      await expectLater(
        service.predictImagePath(imageFile.path),
        throwsA(isA<PlantDiseasePreprocessingNotConfiguredException>()),
      );
      expect(loaderCalled, isFalse);
    });

    test('reports model load failures and permits resource disposal', () async {
      final imageFile = await _temporaryImageFile();
      final service = PlantDiseaseMlService(
        inputScaling: PlantDiseaseInputScaling.rawRgb,
        interpreterLoader: () async => throw StateError('missing model'),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.predictImagePath(imageFile.path),
        throwsA(isA<PlantDiseaseModelLoadException>()),
      );

      final fake = _FakeInterpreter(scores: List<double>.filled(38, 0));
      final loadedService = PlantDiseaseMlService(
        inputScaling: PlantDiseaseInputScaling.rawRgb,
        interpreterLoader: () async => fake,
      );
      await loadedService.predictImagePath(imageFile.path);
      loadedService.dispose();
      loadedService.dispose();
      expect(fake.closed, isTrue);
      await expectLater(
        loadedService.predictImagePath(imageFile.path),
        throwsA(isA<PlantDiseaseMlException>()),
      );
    });

    test(
      'surfaces inference failures instead of producing a prediction',
      () async {
        final imageFile = await _temporaryImageFile();
        final service = PlantDiseaseMlService(
          inputScaling: PlantDiseaseInputScaling.rawRgb,
          interpreterLoader: () async => _FakeInterpreter(
            scores: List<double>.filled(38, 0),
            runError: StateError('inference failed'),
          ),
        );
        addTearDown(service.dispose);

        await expectLater(
          service.predictImagePath(imageFile.path),
          throwsA(isA<PlantDiseaseInferenceException>()),
        );
      },
    );
  });
}

Future<File> _temporaryImageFile({
  int red = 0,
  int green = 0,
  int blue = 0,
}) async {
  final directory = await Directory.systemTemp.createTemp(
    'plant-disease-test-',
  );
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}${Platform.pathSeparator}leaf.png');
  final source = image.Image(width: 2, height: 2, numChannels: 3);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      source.setPixelRgb(x, y, red, green, blue);
    }
  }
  await file.writeAsBytes(image.encodePng(source));
  return file;
}

class _FakeInterpreter implements PlantDiseaseInterpreter {
  final List<double> scores;
  final Object? runError;
  bool closed = false;
  Float32List? receivedInput;

  _FakeInterpreter({required this.scores, this.runError});

  @override
  List<int> get inputShape => [1, 128, 128, 3];

  @override
  bool get inputIsFloat32 => true;

  @override
  List<int> get outputShape => [1, 38];

  @override
  bool get outputIsFloat32 => true;

  @override
  List<double> run(Float32List input) {
    receivedInput = input;
    if (runError != null) throw runError!;
    return scores;
  }

  @override
  void close() => closed = true;
}
