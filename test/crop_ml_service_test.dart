import 'package:flutter_test/flutter_test.dart';
import 'package:jeevandhara/services/crop_ml_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CropMlService service;

  setUp(() {
    service = CropMlService();
  });

  tearDown(() {
    service.dispose();
  });

  test('matches Python predictions and confidence for five samples', () async {
    const samples = [
      (
        nitrogen: 90.0,
        phosphorus: 42.0,
        potassium: 43.0,
        temperature: 20.88,
        humidity: 82.0,
        ph: 6.5,
        crop: 'rice',
        confidence: 0.89,
      ),
      (
        nitrogen: 60.0,
        phosphorus: 40.0,
        potassium: 40.0,
        temperature: 25.0,
        humidity: 80.0,
        ph: 6.5,
        crop: 'jute',
        confidence: 0.6866666667,
      ),
      (
        nitrogen: 100.0,
        phosphorus: 20.0,
        potassium: 50.0,
        temperature: 22.0,
        humidity: 60.0,
        ph: 6.8,
        crop: 'coffee',
        confidence: 0.3766666667,
      ),
      (
        nitrogen: 20.0,
        phosphorus: 130.0,
        potassium: 200.0,
        temperature: 28.0,
        humidity: 85.0,
        ph: 6.2,
        crop: 'grapes',
        confidence: 0.8666666667,
      ),
      (
        nitrogen: 10.0,
        phosphorus: 10.0,
        potassium: 10.0,
        temperature: 18.0,
        humidity: 65.0,
        ph: 7.0,
        crop: 'orange',
        confidence: 0.32,
      ),
    ];

    for (final sample in samples) {
      final prediction = await service.predict(
        nitrogen: sample.nitrogen,
        phosphorus: sample.phosphorus,
        potassium: sample.potassium,
        temperature: sample.temperature,
        humidity: sample.humidity,
        ph: sample.ph,
      );

      expect(prediction.crop, sample.crop);
      expect(prediction.confidence, closeTo(sample.confidence, 0.0001));
      expect(prediction.topCrops, hasLength(3));
      expect(
        orderedDescending.matches(
          prediction.topCrops.map((entry) => entry.probability).toList(),
          const {},
        ),
        isTrue,
      );
    }
  });

  test('rejects non-finite input safely', () async {
    expect(
      () => service.predict(
        nitrogen: double.nan,
        phosphorus: 42.0,
        potassium: 43.0,
        temperature: 20.88,
        humidity: 82.0,
        ph: 6.5,
      ),
      throwsA(isA<CropMlException>()),
    );
  });
}

const orderedDescending = _OrderedDescending();

class _OrderedDescending {
  const _OrderedDescending();

  bool matches(Object? value, Map<dynamic, dynamic> _) {
    if (value is! List<num>) return false;
    for (var index = 1; index < value.length; index++) {
      if (value[index] > value[index - 1]) return false;
    }
    return true;
  }
}
