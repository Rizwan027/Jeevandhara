import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/soil_data_service.dart';

class InputDataScreen extends StatefulWidget {
  const InputDataScreen({super.key});

  @override
  State<InputDataScreen> createState() => _InputDataScreenState();
}

class _InputDataScreenState extends State<InputDataScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phController = TextEditingController(
    text: '6.5',
  );
  final TextEditingController _moistureController = TextEditingController(
    text: '65',
  );
  final TextEditingController _temperatureController = TextEditingController(
    text: '28',
  );
  final TextEditingController _nitrogenController = TextEditingController(
    text: '78',
  );
  final TextEditingController _phosphorusController = TextEditingController(
    text: '82',
  );
  final TextEditingController _potassiumController = TextEditingController(
    text: '71',
  );

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _useSliders = false;

  // Value ranges for sliders
  double _phValue = 6.5;
  double _moistureValue = 65.0;
  double _temperatureValue = 28.0;
  double _nitrogenValue = 78.0;
  double _phosphorusValue = 82.0;
  double _potassiumValue = 71.0;

  // Parameter info for tooltips
  final Map<String, String> _parameterInfo = {
    'pH': 'Soil pH level (4.0-9.0)\nOptimal range: 6.0-7.5',
    'Moisture': 'Soil moisture percentage (0-100%)\nOptimal range: 40-80%',
    'Temperature': 'Soil temperature (0-50°C)\nOptimal range: 15-35°C',
    'Nitrogen': 'Nitrogen content (0-100%)\nEssential for leaf growth',
    'Phosphorus': 'Phosphorus content (0-100%)\nImportant for root development',
    'Potassium': 'Potassium content (0-100%)\nHelps with disease resistance',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Sync controllers with slider values
    _syncControllersWithSliders();
  }

  void _syncControllersWithSliders() {
    _phController.text = _phValue.toStringAsFixed(1);
    _moistureController.text = _moistureValue.toStringAsFixed(0);
    _temperatureController.text = _temperatureValue.toStringAsFixed(0);
    _nitrogenController.text = _nitrogenValue.toStringAsFixed(0);
    _phosphorusController.text = _phosphorusValue.toStringAsFixed(0);
    _potassiumController.text = _potassiumValue.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phController.dispose();
    _moistureController.dispose();
    _temperatureController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF10B981), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: _useSliders ? 'Switch to text input' : 'Switch to sliders',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _useSliders ? Icons.edit : Icons.tune,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _useSliders = !_useSliders;
                        });
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact Header Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.1),
                          const Color(0xFF3B82F6).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Input Data',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'Soil and field parameters',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Compact Soil Parameters Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Section Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Soil Parameters',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Compact Parameters Grid
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactInputField(
                                    'pH',
                                    _phController,
                                    Icons.science,
                                    const Color(0xFF10B981),
                                    _phValue,
                                    4.0,
                                    9.0,
                                    1,
                                    (value) {
                                      setState(() {
                                        _phValue = value;
                                        _phController.text = value.toStringAsFixed(1);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCompactInputField(
                                    'Moisture %',
                                    _moistureController,
                                    Icons.water_drop,
                                    const Color(0xFF3B82F6),
                                    _moistureValue,
                                    0.0,
                                    100.0,
                                    0,
                                    (value) {
                                      setState(() {
                                        _moistureValue = value;
                                        _moistureController.text = value.toStringAsFixed(0);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCompactInputField(
                                    'Temp °C',
                                    _temperatureController,
                                    Icons.thermostat,
                                    const Color(0xFFF59E0B),
                                    _temperatureValue,
                                    0.0,
                                    50.0,
                                    0,
                                    (value) {
                                      setState(() {
                                        _temperatureValue = value;
                                        _temperatureController.text = value.toStringAsFixed(0);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Compact Nutrient Levels Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Compact Header
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_florist,
                                    color: const Color(0xFF10B981),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nutrients (NPK)',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Compact NPK Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactNutrientField(
                                      'N',
                                      _nitrogenController,
                                      const Color(0xFF10B981),
                                      _nitrogenValue,
                                      (value) {
                                        setState(() {
                                          _nitrogenValue = value;
                                          _nitrogenController.text = value.toStringAsFixed(0);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactNutrientField(
                                      'P',
                                      _phosphorusController,
                                      const Color(0xFF3B82F6),
                                      _phosphorusValue,
                                      (value) {
                                        setState(() {
                                          _phosphorusValue = value;
                                          _phosphorusController.text = value.toStringAsFixed(0);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactNutrientField(
                                      'K',
                                      _potassiumController,
                                      const Color(0xFFF59E0B),
                                      _potassiumValue,
                                      (value) {
                                        setState(() {
                                          _potassiumValue = value;
                                          _potassiumController.text = value.toStringAsFixed(0);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save Data Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Saving...',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Soil Data',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
    double value,
    double min,
    double max,
    int decimals,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_useSliders) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  value.toStringAsFixed(decimals),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.3),
                    thumbColor: color,
                    overlayColor: color.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: ((max - min) / (decimals == 0 ? 1 : 0.1)).round(),
                    onChanged: (newValue) {
                      onChanged(newValue);
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,' + decimals.toString() + '}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final numValue = double.tryParse(value);
              if (numValue == null) return 'Invalid';
              if (numValue < min || numValue > max) return '${min.toStringAsFixed(decimals)}-${max.toStringAsFixed(decimals)}';
              return null;
            },
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null && numValue >= min && numValue <= max) {
                onChanged(numValue);
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: color.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactNutrientField(
    String symbol,
    TextEditingController controller,
    Color color,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            symbol,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_useSliders) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  '${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.3),
                    thumbColor: color,
                    overlayColor: color.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (newValue) {
                      onChanged(newValue);
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final numValue = double.tryParse(value);
              if (numValue == null) return 'Invalid';
              if (numValue < 0 || numValue > 100) return '0-100';
              return null;
            },
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null && numValue >= 0 && numValue <= 100) {
                onChanged(numValue);
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: color.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
              suffixText: '%',
              suffixStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              isDense: true,
            ),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }



  Future<void> _saveData() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Sync controllers with slider values
      _syncControllersWithSliders();

      // Prepare soil data
      final soilData = {
        'ph': _phValue,
        'moisture': _moistureValue,
        'temperature': _temperatureValue,
        'nitrogen': _nitrogenValue,
        'phosphorus': _phosphorusValue,
        'potassium': _potassiumValue,
      };

      // Save soil data to local storage
      await SoilDataService.saveSoilData(soilData);

      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 1000));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Soil data saved successfully!',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Check the Advice screen for crop recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 3000),
          ),
        );

        // Navigate back with success haptic
        await Future.delayed(const Duration(milliseconds: 500));
        HapticFeedback.lightImpact();
        
        Navigator.pop(context, true); // Return true to indicate data was saved
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save data. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    HapticFeedback.lightImpact();
  }
}
