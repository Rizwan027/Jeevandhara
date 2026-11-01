import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/tomato_disease_information.dart';
import '../../services/plant_disease_ml_service.dart';

class ScanScreen extends StatefulWidget {
  final bool showBottomNav;

  const ScanScreen({super.key, this.showBottomNav = true});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();
  final PlantDiseaseMlService _plantDiseaseMlService = PlantDiseaseMlService();

  bool _isAnalyzing = false;
  File? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  int _analysisRequestId = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _plantDiseaseMlService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _showPermissionDialog(bool permanentlyDenied) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Camera Permission Required',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            permanentlyDenied
                ? 'Camera access is permanently denied. Open system settings to enable it before taking a photo.'
                : 'Camera access is needed to take a crop photo. You can try again or choose an image from your gallery.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: permanentlyDenied
                  ? () {
                      Navigator.of(context).pop(false);
                      openAppSettings();
                    }
                  : () => Navigator.of(context).pop(true),
              child: Text(
                permanentlyDenied ? 'Settings' : 'Try again',
                style: GoogleFonts.inter(color: const Color(0xFF10B981)),
              ),
            ),
          ],
        );
      },
    );
    return retry ?? false;
  }

  Future<void> _takePlantPhoto() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
      return;
    }

    final retry = await _showPermissionDialog(status.isPermanentlyDenied);
    if (retry && mounted) await _takePlantPhoto();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzePlantHealth() async {
    if (_isAnalyzing || _selectedImage == null) return;
    if (!mounted) return;
    final requestId = ++_analysisRequestId;
    setState(() => _isAnalyzing = true);

    try {
      final imagePath = _selectedImage!.path;
      late final Map<String, dynamic> result;
      try {
        final prediction = await _plantDiseaseMlService.predictImagePath(
          imagePath,
        );
        result = {'model_source': 'plant_disease_38', 'prediction': prediction};
      } on PlantDiseasePreprocessingNotConfiguredException catch (
        error,
        stackTrace
      ) {
        developer.log(
          '38-class inference has no configured input scaling.',
          name: 'ScanScreen',
          error: error,
          stackTrace: stackTrace,
        );
        result = {
          'diagnosis_status': 'unavailable',
          'scan_notice': 'Model input scaling is not configured.',
        };
      } on PlantDiseaseModelLoadException catch (error, stackTrace) {
        developer.log(
          'The 38-class model is unavailable.',
          name: 'ScanScreen',
          error: error,
          stackTrace: stackTrace,
        );
        result = {
          'diagnosis_status': 'unavailable',
          'scan_notice':
              'The 38-class model could not be loaded. No prediction was run.',
        };
      }
      if (!mounted || requestId != _analysisRequestId) return;
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      developer.log('Plant disease scan failed.', name: 'ScanScreen', error: e);
      if (!mounted || requestId != _analysisRequestId) return;
      setState(() => _isAnalyzing = false);
      _showErrorSnackBar('Analysis failed. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetAnalysis() {
    _analysisRequestId++;
    setState(() {
      _analysisResult = null;
      _selectedImage = null;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFE8F5E9).withOpacity(0.3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF087F5B),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Plant Disease Detection',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15352B),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFF10B981),
                      size: 25,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      if (_isAnalyzing)
                        _buildLoadingCard()
                      else if (_analysisResult != null)
                        _buildAnalysisResultCard()
                      else if (_selectedImage != null)
                        _buildImagePreview()
                      else ...[
                        _buildMainActionCard(),
                        const SizedBox(height: 16),
                        _buildPhotographyTips(),
                      ],
                      if (!_isAnalyzing && _analysisResult == null) ...[
                        const SizedBox(height: 18),
                        if (_selectedImage == null)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _takePlantPhoto,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: Text(
                                    'Take Picture',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF087F5B),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: Text(
                                    'Choose from Gallery',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF087F5B),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 8,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFD4E8DE),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _analyzePlantHealth,
                              icon: const Icon(Icons.document_scanner_outlined),
                              label: Text(
                                'Analyze Leaf',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF087F5B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _resetAnalysis,
                            child: Text(
                              'Choose another image',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF60736B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FAF4), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDEFE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E36).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.spa_outlined,
              size: 30,
              color: Color(0xFF087F5B),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'A closer look at your leaves',
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15352B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a clear photo of one leaf to see the model’s plant health prediction.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF5F7169),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotographyTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo tips',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF28483B),
            ),
          ),
          const SizedBox(height: 12),
          _buildPhotoTip(Icons.wb_sunny_outlined, 'Use bright, even light'),
          const SizedBox(height: 9),
          _buildPhotoTip(Icons.center_focus_strong, 'Keep the leaf in focus'),
          const SizedBox(height: 9),
          _buildPhotoTip(Icons.filter_center_focus, 'Show one leaf clearly'),
        ],
      ),
    );
  }

  Widget _buildPhotoTip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10A36F)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF60736B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EEE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E36).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 22),
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A36F)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your plant leaf...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15352B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait while the scan is completed.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF718078),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EEE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E36).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Color(0xFF0B9564),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leaf image ready',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF28483B),
                  ),
                ),
              ),
              Text(
                'Preview',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF839088),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              'Ready for plant health analysis',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF718078),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultCard() {
    final diagnosisStatus = _analysisResult?['diagnosis_status'];
    final rawModelPrediction = _analysisResult?['prediction'];
    final modelPrediction = rawModelPrediction is PlantDiseasePrediction
        ? rawModelPrediction
        : null;
    final topFive =
        modelPrediction?.topFive ?? const <PlantDiseaseClassScore>[];
    final hasClassPrediction =
        _analysisResult?['model_source'] == 'plant_disease_38' &&
        modelPrediction != null;
    final disease = _analysisResult?['disease'];
    final information = disease is String
        ? TomatoDiseaseInformation.forName(disease)
        : null;
    final hasPrediction =
        diagnosisStatus == 'uncertain' &&
        _analysisResult?['crop_type'] == 'Tomato' &&
        disease is String &&
        disease.trim().isNotEmpty &&
        information != null &&
        _analysisResult?['unavailable'] != true &&
        _analysisResult?['error'] != true;
    final isHealthy = hasPrediction && information.isHealthy;
    final modelIsHealthy =
        modelPrediction?.className.endsWith('___healthy') ?? false;
    final isHealthyPrediction = modelPrediction != null
        ? modelIsHealthy
        : isHealthy;
    final healthyExplanation = information?.possibleCause ?? '';
    final heading = modelPrediction != null
        ? modelPrediction.displayLabel
        : hasPrediction
        ? 'Tomato — $disease'
        : switch (diagnosisStatus) {
            'uncertain' => 'Result uncertain',
            'unsupported' => 'Image not supported',
            _ => 'Scan unavailable',
          };
    final message = switch (diagnosisStatus) {
      'uncertain' =>
        'The image could not be classified reliably. Try a clear photo of one tomato leaf.',
      'unsupported' =>
        'This image is not supported for tomato disease scanning.',
      'unavailable' => 'An ML prediction is unavailable for this image.',
      _ => 'The scan could not be completed. Try a clear photo of one leaf.',
    };
    final sections = isHealthy
        ? <(String, Object?)>[]
        : <(String, Object?)>[
            ('Possible cause', _resultSectionValue('possible_cause')),
            ('What to do', _resultSectionValue('recommended_actions')),
            ('Prevention', _resultSectionValue('prevention')),
          ].where((section) => section.$2 != null).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPrediction || hasClassPrediction
                      ? isHealthyPrediction
                            ? Icons.check_rounded
                            : Icons.spa_outlined
                      : Icons.info_outline,
                  color: hasPrediction || hasClassPrediction
                      ? const Color(0xFF087F5B)
                      : const Color(0xFF9A6B16),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  heading,
                  style: GoogleFonts.inter(
                    fontSize: hasPrediction || hasClassPrediction ? 22 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15352B),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (hasPrediction || hasClassPrediction) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHealthyPrediction
                    ? const Color(0xFFE8F6EC)
                    : const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHealthyPrediction
                        ? Icons.verified_outlined
                        : Icons.health_and_safety_outlined,
                    size: 17,
                    color: isHealthyPrediction
                        ? const Color(0xFF087F5B)
                        : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isHealthyPrediction ? 'Healthy result' : 'Disease detected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isHealthyPrediction
                          ? const Color(0xFF087F5B)
                          : const Color(0xFF9A4D0A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (_analysisResult?['scan_notice'] case final String notice) ...[
            Text(
              notice,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9A6B16),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (modelPrediction != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCEDE2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF087F5B),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Model confidence score',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF496257),
                      ),
                    ),
                  ),
                  Text(
                    modelPrediction.scores[modelPrediction.predictedIndex]
                        .toStringAsFixed(4),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF087F5B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < topFive.length; index++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE8EFEB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            topFive[index].index ==
                                modelPrediction.predictedIndex
                            ? const Color(0xFFDDF4E6)
                            : const Color(0xFFEDF1EE),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF476056),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topFive[index].displayLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              topFive[index].index ==
                                  modelPrediction.predictedIndex
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF40544A),
                        ),
                      ),
                    ),
                    Text(
                      topFive[index].score.toStringAsFixed(4),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF60736B),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Scores are model outputs, not calibrated probabilities or a confirmed diagnosis.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF78857E),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ] else if (hasPrediction) ...[
            if (isHealthy)
              Text(
                healthyExplanation,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              )
            else
              for (var index = 0; index < sections.length; index++) ...[
                _buildResultSection(sections[index].$1, sections[index].$2!),
                if (index < sections.length - 1) const SizedBox(height: 12),
              ],
            const SizedBox(height: 14),
            Text(
              'Unverified model prediction — not a confirmed diagnosis.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetAnalysis,
              icon: const Icon(Icons.center_focus_strong, color: Colors.white),
              label: Text(
                'Scan Another Leaf',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087F5B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Object? _resultSectionValue(String key) {
    final value = _analysisResult?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.every((item) => item is String)) {
      final items = value.cast<String>().where(
        (item) => item.trim().isNotEmpty,
      );
      final nonEmptyItems = items.toList(growable: false);
      return nonEmptyItems.isEmpty ? null : nonEmptyItems;
    }
    return null;
  }

  Widget _buildResultSection(String title, Object content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF087F5B),
            ),
          ),
          const SizedBox(height: 5),
          if (content is String)
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF374151),
              ),
            )
          else if (content is List<String>)
            for (final item in content)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.45,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
