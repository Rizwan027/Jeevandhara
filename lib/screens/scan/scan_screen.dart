import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../models/tomato_disease_information.dart';
import '../../services/ai_service.dart';

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
  final AIService _aiService = AIService();

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status != PermissionStatus.granted) {
      _showPermissionDialog(status.isPermanentlyDenied);
    }
  }

  void _showPermissionDialog(bool permanentlyDenied) {
    showDialog(
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
                : 'Camera access is needed to take a crop photo. You can still choose an image from your gallery.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Settings',
                style: GoogleFonts.inter(color: const Color(0xFF10B981)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePlantPhoto() async {
    await _requestCameraPermission();
    if (!mounted) return;
    if (await Permission.camera.isGranted) {
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
        await _analyzePlantHealth();
      }
    }
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
        await _analyzePlantHealth();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzePlantHealth() async {
    if (_selectedImage == null) return;
    if (!mounted) return;
    final requestId = ++_analysisRequestId;
    setState(() => _isAnalyzing = true);

    try {
      // Call AI service for plant health analysis
      final result = await _aiService.analyzePlantHealth(_selectedImage!.path);
      if (!mounted || requestId != _analysisRequestId) return;
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF10B981),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Crop Health Scanner',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (_analysisResult == null)
                  Text(
                    'AI predictions are not confirmed diagnoses.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                const SizedBox(height: 24),

                // Analysis Status Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_isAnalyzing)
                          _buildLoadingCard()
                        else if (_analysisResult != null)
                          _buildAnalysisResultCard()
                        else if (_selectedImage != null)
                          _buildImagePreview()
                        else
                          _buildMainActionCard(),
                      ],
                    ),
                  ),
                ),

                // Action Buttons Section
                if (!_isAnalyzing && _analysisResult == null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePlantPhoto,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Take Photo',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(
                            Icons.photo_library,
                            color: Color(0xFF10B981),
                          ),
                          label: Text(
                            'Gallery',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF10B981)),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedImage != null || _analysisResult != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _resetAnalysis,
                        child: Text(
                          'Start New Analysis',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, size: 40, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 20),
          Text(
            'AI Crop Health Analysis',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This experimental model selects only among eight tomato categories. It is not field-validated and cannot identify non-tomato or unrecognized conditions.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing image...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Image Selected',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for analysis',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultCard() {
    final diagnosisStatus = _analysisResult?['diagnosis_status'];
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
    final healthyExplanation = information?.possibleCause ?? '';
    final heading = hasPrediction
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
                  color: const Color(0xFF10B981).withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPrediction ? Icons.eco_outlined : Icons.info_outline,
                  color: hasPrediction
                      ? const Color(0xFF10B981)
                      : const Color(0xFF9A6B16),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  heading,
                  style: GoogleFonts.inter(
                    fontSize: hasPrediction ? 22 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 168,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (hasPrediction) ...[
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
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Scan another image',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
