import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../chat/chat_screen.dart';
import '../../services/weather_service.dart';
import '../../services/soil_data_service.dart';

class AdviceScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const AdviceScreen({super.key, this.showBottomNav = false});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, double>? soilData;
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  List<Map<String, dynamic>> recommendedCrops = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadDataAndGenerateRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDataAndGenerateRecommendations() async {
    try {
      // Load soil data
      soilData = await SoilDataService.getSoilData();
      
      // Load weather data with fallback
      try {
        final weatherService = WeatherService();
        final weather = await weatherService.getCurrentWeather();
        if (weather != null) {
          weatherData = {
            'temperature': weather.temperature,
            'humidity': weather.humidity,
            'rainfall': 800.0,
          };
        } else {
          weatherData = _getDefaultWeatherData();
        }
      } catch (e) {
        weatherData = _getDefaultWeatherData();
      }
      
      // Generate recommendations
      recommendedCrops = _generateCropRecommendations();
      
      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  Map<String, dynamic> _getDefaultWeatherData() {
    return {
      'temperature': 25.0,
      'humidity': 65.0,
      'rainfall': 800.0,
    };
  }

  List<Map<String, dynamic>> _generateCropRecommendations() {
    final month = DateTime.now().month;
    String season = _getCurrentSeason(month);
    
    // Default values
    final ph = soilData?['ph'] ?? 6.5;
    final temperature = weatherData?['temperature'] ?? 25.0;
    final rainfall = weatherData?['rainfall'] ?? 800.0;
    
    List<Map<String, dynamic>> crops = [];
    
    if (season == 'rabi') {
      // Winter season crops (Nov-Mar)
      crops = [
        {
          'name': 'Wheat',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'wheat'),
          'reason': 'Ideal winter crop for current soil and weather conditions',
          'expectedYield': '4-5 tons/hectare',
          'duration': '120-150 days',
          'profit': '₹25,000-35,000/hectare',
          'icon': FontAwesomeIcons.wheatAwn,
          'color': const Color(0xFFFF9800),
        },
        {
          'name': 'Mustard',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'mustard'),
          'reason': 'Excellent oilseed crop for winter season',
          'expectedYield': '1.5-2 tons/hectare',
          'duration': '90-120 days',
          'profit': '₹20,000-30,000/hectare',
          'icon': FontAwesomeIcons.sun,
          'color': const Color(0xFFFFC107),
        },
        {
          'name': 'Gram (Chickpea)',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'gram'),
          'reason': 'Nitrogen-fixing legume that improves soil health',
          'expectedYield': '1.5-2.5 tons/hectare',
          'duration': '100-120 days',
          'profit': '₹30,000-45,000/hectare',
          'icon': FontAwesomeIcons.spa,
          'color': const Color(0xFF795548),
        },
      ];
    } else if (season == 'kharif') {
      // Monsoon season crops (Jun-Oct)
      crops = [
        {
          'name': 'Rice (Paddy)',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'rice'),
          'reason': 'Perfect monsoon crop with high water availability',
          'expectedYield': '4-6 tons/hectare',
          'duration': '120-150 days',
          'profit': '₹35,000-50,000/hectare',
          'icon': FontAwesomeIcons.seedling,
          'color': const Color(0xFF4CAF50),
        },
        {
          'name': 'Cotton',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'cotton'),
          'reason': 'Valuable cash crop suitable for warm, wet conditions',
          'expectedYield': '15-20 quintals/hectare',
          'duration': '180-200 days',
          'profit': '₹60,000-80,000/hectare',
          'icon': FontAwesomeIcons.cloudRain,
          'color': const Color(0xFFFFEB3B),
        },
      ];
    } else {
      // Summer season crops (Apr-May)
      crops = [
        {
          'name': 'Watermelon',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'watermelon'),
          'reason': 'Heat-tolerant crop perfect for summer conditions',
          'expectedYield': '25-35 tons/hectare',
          'duration': '90-110 days',
          'profit': '₹40,000-60,000/hectare',
          'icon': FontAwesomeIcons.appleWhole,
          'color': const Color(0xFFE91E63),
        },
        {
          'name': 'Cucumber',
          'suitability': _calculateSuitability(ph, temperature, rainfall, 'cucumber'),
          'reason': 'Quick-growing summer vegetable with good returns',
          'expectedYield': '15-20 tons/hectare',
          'duration': '60-80 days',
          'profit': '₹25,000-35,000/hectare',
          'icon': FontAwesomeIcons.leaf,
          'color': const Color(0xFF4CAF50),
        },
      ];
    }
    
    crops.sort((a, b) => (b['suitability'] as double).compareTo(a['suitability'] as double));
    return crops;
  }

  List<Map<String, dynamic>> _getCropsToAvoid() {
    final month = DateTime.now().month;
    String season = _getCurrentSeason(month);
    final ph = soilData?['ph'] ?? 6.5;
    final temperature = weatherData?['temperature'] ?? 25.0;
    final rainfall = weatherData?['rainfall'] ?? 800.0;
    
    List<Map<String, dynamic>> cropsToAvoid = [];
    
    if (season == 'rabi') {
      // Avoid monsoon crops in winter
      if (rainfall < 600) {
        cropsToAvoid.add({
          'name': 'Rice',
          'reason': 'Insufficient water availability for paddy cultivation',
          'icon': Icons.water_drop_outlined,
          'color': Colors.red,
        });
      }
      if (temperature > 30) {
        cropsToAvoid.add({
          'name': 'Peas',
          'reason': 'Too warm for cool season legumes',
          'icon': Icons.thermostat,
          'color': Colors.orange,
        });
      }
    } else if (season == 'kharif') {
      // Avoid winter crops in monsoon
      if (rainfall > 1200) {
        cropsToAvoid.add({
          'name': 'Wheat',
          'reason': 'Excessive moisture can cause fungal diseases',
          'icon': Icons.water_damage,
          'color': Colors.red,
        });
      }
    }
    
    // pH-based restrictions
    if (ph < 5.5) {
      cropsToAvoid.add({
        'name': 'Barley',
        'reason': 'Soil too acidic (pH < 5.5)',
        'icon': Icons.science,
        'color': Colors.red,
      });
    }
    if (ph > 8.0) {
      cropsToAvoid.add({
        'name': 'Potato',
        'reason': 'Soil too alkaline (pH > 8.0)',
        'icon': Icons.science,
        'color': Colors.red,
      });
    }
    
    return cropsToAvoid.take(2).toList();
  }

  Map<String, Map<String, String>> _getMarketPrices() {
    return {
      'Wheat': {
        'currentPrice': '₹2,180/quintal',
        'trend': '↑ +2.5%',
        'trendColor': 'green'
      },
      'Rice': {
        'currentPrice': '₹2,850/quintal',
        'trend': '↑ +5.2%',
        'trendColor': 'green'
      },
      'Mustard': {
        'currentPrice': '₹5,420/quintal',
        'trend': '↓ -1.8%',
        'trendColor': 'red'
      },
      'Gram': {
        'currentPrice': '₹5,180/quintal',
        'trend': '↑ +3.1%',
        'trendColor': 'green'
      },
      'Cotton': {
        'currentPrice': '₹6,240/quintal',
        'trend': '→ 0.0%',
        'trendColor': 'grey'
      },
    };
  }

  String _getCurrentSeason(int month) {
    if (month >= 6 && month <= 10) return 'kharif';
    if (month >= 11 || month <= 3) return 'rabi';
    return 'summer';
  }

  double _calculateSuitability(double ph, double temp, double rainfall, String cropType) {
    double score = 0.0;
    
    switch (cropType) {
      case 'wheat':
        score += (ph >= 6.0 && ph <= 7.5) ? 40 : 20;
        score += (temp >= 15 && temp <= 25) ? 35 : 20;
        score += (rainfall >= 400 && rainfall <= 1000) ? 25 : 15;
        break;
      case 'rice':
        score += (ph >= 5.5 && ph <= 7.0) ? 40 : 25;
        score += (temp >= 20 && temp <= 35) ? 35 : 20;
        score += (rainfall >= 800) ? 25 : 15;
        break;
      case 'cotton':
        score += (ph >= 5.8 && ph <= 8.0) ? 40 : 25;
        score += (temp >= 22 && temp <= 35) ? 35 : 20;
        score += (rainfall >= 500 && rainfall <= 1200) ? 25 : 15;
        break;
      default:
        score = 70.0;
    }
    
    return score.clamp(50.0, 95.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: Text(
          'Crop Recommendations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: !widget.showBottomNav,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 12),
                    _buildCropRecommendations(),
                    const SizedBox(height: 12),
                    _buildCropsToAvoid(),
                    const SizedBox(height: 12),
                    _buildMarketPrices(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  Widget _buildSummaryCard() {
    final hasData = soilData != null;
    final season = _getCurrentSeason(DateTime.now().month);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.seedling,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Crop Recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (!hasData) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/input_data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4CAF50),
              ),
              child: Text(
                'Add Soil Data',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCropRecommendations() {
    if (recommendedCrops.isEmpty) {
      return _buildNoCropsFound();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Crops',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        ...recommendedCrops.asMap().entries.map((entry) {
          final index = entry.key;
          final crop = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == recommendedCrops.length - 1 ? 0 : 8),
            child: _buildCropCard(crop, index),
          );
        }),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop, int index) {
    final suitability = crop['suitability'] as double;
    final suitabilityText = suitability >= 80 ? 'Excellent' : suitability >= 70 ? 'Good' : suitability >= 60 ? 'Fair' : 'Poor';
    final suitabilityColor = suitability >= 80 ? Colors.green : suitability >= 70 ? Colors.lightGreen : suitability >= 60 ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: index == 0 ? const Color(0xFF4CAF50).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: index == 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (crop['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: FaIcon(crop['icon'], color: crop['color'], size: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crop['name'],
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                          ),
                        ),
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(8)),
                            child: Text('BEST', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: suitabilityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('$suitabilityText (${suitability.toInt()}%)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: suitabilityColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(crop['reason'], style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1B5E20), height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Yield', crop['expectedYield'], Icons.trending_up)),
              Expanded(child: _buildInfoItem('Duration', crop['duration'], Icons.schedule)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Expected Profit', crop['profit'], Icons.attach_money, isProfit: true),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {bool isProfit = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isProfit ? Colors.green : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isProfit ? Colors.green : const Color(0xFF2E7D32))),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildCropsToAvoid() {
    final cropsToAvoid = _getCropsToAvoid();
    
    if (cropsToAvoid.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crops to Avoid',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        ...cropsToAvoid.map((crop) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(crop['icon'], color: crop['color'], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop['name'],
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[700]),
                    ),
                    Text(
                      crop['reason'],
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMarketPrices() {
    final marketPrices = _getMarketPrices();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Market Prices',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: marketPrices.entries.take(4).map((entry) {
              final crop = entry.key;
              final data = entry.value;
              final trendColor = data['trendColor'] == 'green' ? Colors.green 
                                : data['trendColor'] == 'red' ? Colors.red 
                                : Colors.grey;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        crop,
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        data['currentPrice']!,
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        data['trend']!,
                        style: GoogleFonts.poppins(fontSize: 10, color: trendColor, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Advice tab
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(showBottomNav: true)),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen(showBottomNav: true)),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen(showBottomNav: true)),
          );
        }
        // Current tab (advice) - no action needed
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: const Color(0xFF9CA3AF),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      backgroundColor: Colors.white,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      iconSize: 22,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Advice'),
        BottomNavigationBarItem(
          icon: Icon(Icons.eco),
          label: 'Scan Crop',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}

  Widget _buildNoCropsFound() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No Suitable Crops Found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current conditions may not be optimal. Consider improving soil health or wait for better weather.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }