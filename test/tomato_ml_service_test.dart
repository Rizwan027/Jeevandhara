import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:jeevandhara/models/crop_diagnosis_result.dart';
import 'package:jeevandhara/models/tomato_disease_information.dart';
import 'package:jeevandhara/services/tomato_ml_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TomatoMlService', () {
    test('normalizes RGB pixels into NCHW planes after a center crop', () {
      final source = image.Image(width: 300, height: 256, numChannels: 3);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(x, y, x % 256, 10, 20);
        }
      }

      final tensor = TomatoMlService.preprocessImageBytes(
        image.encodePng(source),
      );
      const planeSize = 224 * 224;

      expect(tensor, isA<Float32List>());
      expect(tensor.length, 3 * planeSize);
      expect(tensor[0], closeTo(((38 / 255) - 0.485) / 0.229, 1e-6));
      expect(tensor[planeSize], closeTo(((10 / 255) - 0.456) / 0.224, 1e-6));
      expect(
        tensor[2 * planeSize],
        closeTo(((20 / 255) - 0.406) / 0.225, 1e-6),
      );
      expect(tensor[100], closeTo(((138 / 255) - 0.485) / 0.229, 1e-6));
    });

    test('resizes the shortest edge to 256 with bilinear interpolation', () {
      final source = image.Image(width: 600, height: 300, numChannels: 3);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(x, y, x % 256, y % 256, 40);
        }
      }

      final tensor = TomatoMlService.preprocessImageBytes(
        image.encodePng(source),
      );
      const planeSize = 224 * 224;

      expect(tensor.length, 3 * planeSize);
      expect(tensor[0], closeTo(((168 / 255) - 0.485) / 0.229, 1e-6));
      expect(tensor[planeSize], closeTo(((18 / 255) - 0.456) / 0.224, 1e-6));
    });

    test('preserves the existing eight-class output order', () {
      expect(TomatoMlService.tomatoClassNames, [
        'Tomato___Bacterial_spot',
        'Tomato___Early_blight',
        'Tomato___Late_blight',
        'Tomato___Leaf_Mold',
        'Tomato___Septoria_leaf_spot',
        'Tomato___Spider_mites Two-spotted_spider_mite',
        'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
        'Tomato___healthy',
      ]);
    });

    test('maps finite logits to unverified readable tomato categories', () {
      for (var index = 0; index < 8; index++) {
        final logits = List<num>.filled(8, -1)..[index] = 4;
        final result = TomatoMlService.classifyLogits(logits);
        final expectedLabel = TomatoDiseaseInformation.forModelLabel(
          TomatoMlService.tomatoClassNames[index],
        )!.name;

        expect(result.status, CropDiagnosisStatus.uncertain);
        expect(result.cropLabel, 'Tomato');
        expect(result.diseaseLabel, expectedLabel);
        expect(result.confidence, isNull);
      }
    });

    test('selects guidance matching each top model category', () async {
      final imageFile = await _temporaryImageFile();
      for (var index = 0; index < 8; index++) {
        final expected = TomatoDiseaseInformation.forModelLabel(
          TomatoMlService.tomatoClassNames[index],
        )!;
        final service = TomatoMlService.forTesting(
          modelRunner: (_) async => List<num>.filled(8, -1)..[index] = 4,
        );

        final result = await service.analyzePlantHealth(imageFile.path);

        expect(result['disease'], expected.name);
        if (expected.isHealthy) {
          expect(result['healthy_explanation'], expected.possibleCause);
          expect(result.containsKey('recommended_actions'), isFalse);
        } else {
          expect(result['possible_cause'], expected.possibleCause);
          expect(result['recommended_actions'], expected.recommendedActions);
          expect(result['prevention'], expected.prevention);
        }
      }
    });

    test(
      'mocked unrelated-image logits return an unverified top category',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'tomato-unrelated-image-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final imageFile = File(
          '${directory.path}${Platform.pathSeparator}image.png',
        );
        await imageFile.writeAsBytes(
          image.encodePng(image.Image(width: 64, height: 64)),
        );
        var runnerCalled = false;
        final service = TomatoMlService.forTesting(
          modelRunner: (tensor) async {
            runnerCalled = true;
            expect(tensor.length, 3 * 224 * 224);
            return [0, 9, 0, 0, 0, 0, 0, 0];
          },
        );

        final result = await service.analyzePlantHealth(imageFile.path);

        expect(runnerCalled, isTrue);
        expect(result['diagnosis_status'], 'uncertain');
        expect(result['crop_type'], 'Tomato');
        expect(result['disease'], 'Early Blight');
        expect(result['confidence'], isNull);
        expect(
          result['prediction_note'],
          'Unverified model prediction — not a confirmed diagnosis.',
        );
        expect(result['possible_cause'], contains('concentric'));
        expect(result['recommended_actions'], isNotEmpty);
        // Mocked logits test mapping only, not real-image rejection.
      },
    );

    test('healthy category has no disease treatment recommendations', () async {
      final imageFile = await _temporaryImageFile();
      final service = TomatoMlService.forTesting(
        modelRunner: (_) async => [0, 0, 0, 0, 0, 0, 0, 10],
      );

      final result = await service.analyzePlantHealth(imageFile.path);

      expect(result['disease'], 'Healthy');
      expect(result['diagnosis_status'], 'uncertain');
      expect(result['confidence'], isNull);
      expect(result['healthy_explanation'], contains('does not guarantee'));
      expect(result.containsKey('recommended_actions'), isFalse);
      expect(result.containsKey('prevention'), isFalse);
    });

    test('all disease categories have guidance and references', () {
      final diseaseInformation = TomatoDiseaseInformation.byModelLabel.values
          .where((information) => !information.isHealthy);

      expect(diseaseInformation, hasLength(7));
      for (final information in diseaseInformation) {
        expect(information.name, isNotEmpty);
        expect(information.possibleCause, isNotEmpty);
        expect(information.recommendedActions, isNotEmpty);
        expect(information.prevention, isNotEmpty);
        expect(information.references, isNotEmpty);
      }
    });

    test('uncertain result without a category has no disease guidance', () {
      final result = CropDiagnosisResult.uncertain().toLegacyMap();

      expect(result['diagnosis_status'], 'uncertain');
      expect(result['disease'], isNull);
      expect(result['error'], isFalse);
      expect(result.containsKey('possible_cause'), isFalse);
      expect(result.containsKey('recommended_actions'), isFalse);
      expect(result.containsKey('prevention'), isFalse);
    });

    test(
      'invalid mocked outputs return unavailable without a prediction',
      () async {
        final imageFile = await _temporaryImageFile();
        final service = TomatoMlService.forTesting(
          modelRunner: (_) async => [0, 1],
        );

        final result = await service.analyzePlantHealth(imageFile.path);

        expect(result['diagnosis_status'], 'unavailable');
        expect(result['crop_type'], isNull);
        expect(result['disease'], isNull);
        expect(result.containsKey('possible_cause'), isFalse);
        expect(result.containsKey('recommended_actions'), isFalse);
        expect(result.containsKey('prevention'), isFalse);
      },
    );

    test(
      'inference exceptions return unavailable without a prediction',
      () async {
        final imageFile = await _temporaryImageFile();
        final service = TomatoMlService.forTesting(
          modelRunner: (_) async => throw StateError('mock inference failure'),
        );

        final result = await service.analyzePlantHealth(imageFile.path);

        expect(result['diagnosis_status'], 'unavailable');
        expect(result['crop_type'], isNull);
        expect(result['disease'], isNull);
        expect(result.containsKey('possible_cause'), isFalse);
        expect(result.containsKey('recommended_actions'), isFalse);
        expect(result.containsKey('prevention'), isFalse);
      },
    );

    test('rejects malformed or non-finite model outputs', () {
      expect(
        () => TomatoMlService.classifyLogits([0, 1]),
        throwsFormatException,
      );
      expect(
        () => TomatoMlService.classifyLogits([0, 0, double.nan, 0, 0, 0, 0, 0]),
        throwsFormatException,
      );
      expect(
        () => TomatoMlService.preprocessImageBytes(Uint8List(0)),
        throwsFormatException,
      );
    });
  });
}

Future<File> _temporaryImageFile() async {
  final directory = await Directory.systemTemp.createTemp('tomato-test-image-');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}${Platform.pathSeparator}image.png');
  await file.writeAsBytes(image.encodePng(image.Image(width: 64, height: 64)));
  return file;
}
