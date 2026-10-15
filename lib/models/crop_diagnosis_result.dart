enum CropDiagnosisStatus { unavailable, uncertain, diagnosis, unsupported }

class CropDiagnosisResult {
  final CropDiagnosisStatus status;
  final String? cropLabel;
  final String? diseaseLabel;
  final double? confidence;

  const CropDiagnosisResult._({
    required this.status,
    this.cropLabel,
    this.diseaseLabel,
    this.confidence,
  });

  const CropDiagnosisResult.unavailable()
    : this._(status: CropDiagnosisStatus.unavailable);

  const CropDiagnosisResult.unsupported()
    : this._(status: CropDiagnosisStatus.unsupported);

  factory CropDiagnosisResult.uncertain({
    String? cropLabel,
    String? diseaseLabel,
    double? confidence,
  }) {
    _validateOptionalLabel(cropLabel);
    _validateOptionalLabel(diseaseLabel);
    _validateOptionalConfidence(confidence);
    return CropDiagnosisResult._(
      status: CropDiagnosisStatus.uncertain,
      cropLabel: cropLabel,
      diseaseLabel: diseaseLabel,
      confidence: confidence,
    );
  }

  factory CropDiagnosisResult.diagnosis({
    required String cropLabel,
    required String diseaseLabel,
    required double confidence,
  }) {
    _validateRequiredLabel(cropLabel, 'cropLabel');
    _validateRequiredLabel(diseaseLabel, 'diseaseLabel');
    _validateOptionalConfidence(confidence);
    return CropDiagnosisResult._(
      status: CropDiagnosisStatus.diagnosis,
      cropLabel: cropLabel,
      diseaseLabel: diseaseLabel,
      confidence: confidence,
    );
  }

  Map<String, dynamic> toLegacyMap() {
    final isUnavailable =
        status == CropDiagnosisStatus.unavailable ||
        status == CropDiagnosisStatus.unsupported;
    return {
      'diagnosis_status': status.name,
      'status': switch (status) {
        CropDiagnosisStatus.unavailable =>
          'Crop diagnosis is unavailable in this version.',
        CropDiagnosisStatus.uncertain =>
          'The image could not be classified reliably.',
        CropDiagnosisStatus.diagnosis => 'Crop diagnosis result available.',
        CropDiagnosisStatus.unsupported =>
          'This crop, image, or condition is outside the supported scope.',
      },
      'confidence': confidence,
      if (cropLabel != null) 'crop_type': cropLabel,
      if (diseaseLabel != null) 'disease': diseaseLabel,
      'recommendations': switch (status) {
        CropDiagnosisStatus.unavailable =>
          'This image has not been analyzed. Do not use this screen to make treatment or pesticide decisions. Consult a qualified agricultural expert for diagnosis.',
        CropDiagnosisStatus.uncertain =>
          'No reliable diagnosis is available. Consult a qualified agricultural expert.',
        CropDiagnosisStatus.diagnosis => '',
        CropDiagnosisStatus.unsupported =>
          'No diagnosis is available for this crop, image, or condition. Consult a qualified agricultural expert.',
      },
      'error': status == CropDiagnosisStatus.unavailable,
      'unavailable': isUnavailable,
    };
  }

  static void _validateRequiredLabel(String label, String name) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, name, 'must not be empty');
    }
  }

  static void _validateOptionalLabel(String? label) {
    if (label != null) _validateRequiredLabel(label, 'label');
  }

  static void _validateOptionalConfidence(double? confidence) {
    if (confidence != null &&
        (!confidence.isFinite || confidence < 0 || confidence > 1)) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'must be finite and between 0 and 1',
      );
    }
  }
}
