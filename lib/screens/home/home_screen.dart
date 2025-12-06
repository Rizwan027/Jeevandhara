import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jeevandhara/screens/advice/advice_screen.dart';
import 'package:jeevandhara/screens/chat/chat_screen.dart';
import 'package:jeevandhara/screens/scan/scan_screen.dart';
import 'package:jeevandhara/screens/input_data/input_data_screen.dart';
import 'package:jeevandhara/services/weather_service.dart';
import 'package:jeevandhara/services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const HomeScreen({super.key, this.showBottomNav = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late WeatherService _weatherService;
  late AIService _aiService;
  
  int _currentIndex = 0;
  WeatherData? _currentWeather;
  List<WeatherAlert> _weatherAlerts = [];
  List<WeatherForecast> _weatherForecast = [];
  String _aiRecommendation = '';
  bool _isLoadingWeather = true;
  bool _isLoadingAI = true;

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService();
    _aiService = AIService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    
    // Load weather data and AI recommendations
    _loadWeatherData();
    _loadAIRecommendations();
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getWeatherForecast();
      
      if (weather != null) {
        final alerts = _weatherService.generateFarmingAlerts(weather, forecast);
        
        if (mounted) {
          setState(() {
            _currentWeather = weather;
            _weatherForecast = forecast;
            _weatherAlerts = alerts;
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _loadAIRecommendations() async {
    try {
      String weatherContext = '';
      if (_currentWeather != null) {
        weatherContext = 'Current weather: ${_currentWeather!.temperature.round()}°C, ${_currentWeather!.description}, ${_currentWeather!.humidity}% humidity. ';
      }
      
      final recommendation = await _aiService.getAgriculturalAdvice(
        '${weatherContext}Give me 3 important farming recommendations for today based on current conditions.'
      );
      
      if (mounted) {
        setState(() {
          _aiRecommendation = recommendation;
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      print('Error loading AI recommendations: $e');
      if (mounted) {
        setState(() {
          _aiRecommendation = '''🌾 Today's Farming Tips:

• Check soil moisture levels - water if dry
• Monitor crops for pest activity 
• Apply organic fertilizer if needed

💡 Use our AI chat for personalized advice!''';
          _isLoadingAI = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) return; // Already on Home

    setState(() {
      _currentIndex = index;
    });

    Future<void>? navigation;

    if (index == 1) {
      // Scan tab
      navigation = Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen(showBottomNav: true)),
      );
    } else if (index == 2) {
      // Chat tab
      navigation = Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen(showBottomNav: true)),
      );
    } else if (index == 3) {
      // Advice tab
      navigation = Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdviceScreen(showBottomNav: true)),
      );
    } else if (index == 4) {
      // Profile tab - TODO: implement profile screen
      // navigation = Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => const ProfileScreen()),
      // );
    }

    // When the pushed screen is popped (back button), reset to Home tab.
    navigation?.then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_getTimeOfDay()}!',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hello Farmer',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        // Profile and notification
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: const Color(0xFF6B7280),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
              
              // Main Content Cards
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Alerts Section
                    _buildSectionTitle('Today\'s Alerts'),
                    const SizedBox(height: 16),
                    _buildAlertCards(),
                    
                    const SizedBox(height: 32),
                    
                    // Soil Status Section
                    _buildSectionTitle('Soil Status'),
                    const SizedBox(height: 16),
                    _buildEnhancedSoilStatusCard(),
                    
                    const SizedBox(height: 32),
                    
                    // Weather Forecast Section
                    _buildSectionTitle('Weather Forecast'),
                    const SizedBox(height: 16),
                    _buildWeatherForecastCard(),
                    
                    const SizedBox(height: 32),
                    
                    // AI Recommendations Section
                    _buildAIRecommendationsSection(),
                    
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Advice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ) : null,
    );
  }

  // Helper method for time-based greeting
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            'Crop\nAdvice',
            Icons.eco_outlined,
            const Color(0xFF10B981),
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdviceScreen(showBottomNav: true))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            'Add\nData',
            Icons.add_circle_outline,
            const Color(0xFF3B82F6),
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InputDataScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildInsightCards() {
    return Column(
      children: [
        // Weather Card
        if (_currentWeather != null) ...[
          _buildWeatherCard(),
          const SizedBox(height: 16),
        ],
        // Crop Insights Row
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Crop Health',
                '92%',
                '+2.3% from last week',
                Icons.eco_outlined,
                const Color(0xFF10B981),
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                'Yield Est.',
                '847 kg',
                'Expected this season',
                Icons.trending_up_outlined,
                const Color(0xFF3B82F6),
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    if (_currentWeather == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentWeather!.temperature.round()}°C',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _currentWeather!.cityName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentWeather!.description.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_currentWeather!.humidity}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      'Humidity',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color, bool showTrend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (showTrend)
                Icon(Icons.trending_up, color: const Color(0xFF10B981), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: showTrend ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCards() {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    List<Widget> alertWidgets = [];

    // Add weather alerts
    for (var alert in _weatherAlerts) {
      alertWidgets.add(_buildWeatherAlertCard(alert));
      alertWidgets.add(const SizedBox(height: 12));
    }

    // Add market alert as fallback or additional info
    alertWidgets.add(_buildAlertCard(
      'Rice prices increased in market',
      'Rice prices have increased by 8% in the local market.',
      Icons.trending_up_outlined,
      const Color(0xFFF59E0B),
    ));

    return Column(children: alertWidgets);
  }

  Widget _buildWeatherAlertCard(WeatherAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.severity) {
      case AlertSeverity.urgent:
        alertColor = const Color(0xFFDC2626);
        alertIcon = Icons.warning_outlined;
        break;
      case AlertSeverity.warning:
        alertColor = const Color(0xFFF59E0B);
        alertIcon = Icons.info_outlined;
        break;
      case AlertSeverity.info:
        alertColor = const Color(0xFF3B82F6);
        alertIcon = Icons.info_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertColor.withOpacity(0.2), 
          width: alert.severity == AlertSeverity.urgent ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                alert.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (alert.severity == AlertSeverity.urgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'URGENT',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (alert.actionRequired)
            Icon(
              Icons.chevron_right,
              color: alertColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pH Level: 6.5',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Optimal for most crops',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.65,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherForecastCard() {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weather Forecast',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Current Weather Information
          if (_currentWeather != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current weather header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Weather',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currentWeather!.cityName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Current weather details
                  Column(
                    children: [
                      // Top row - Temperature and Humidity
                      Row(
                        children: [
                          // Temperature section
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_currentWeather!.temperature.round()}',
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      Text(
                                        '°C',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Temperature',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Humidity section
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${_currentWeather!.humidity}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Humidity',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bottom row - Climate
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getWeatherIcon(_currentWeather!.description),
                              size: 18,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentWeather!.description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
          
          // 5-Day Forecast
          if (_weatherForecast.isNotEmpty) ...[
            Text(
              '5-Day Forecast',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weatherForecast.length,
                itemBuilder: (context, index) {
                  final forecast = _weatherForecast[index];
                  final isToday = index == 0;
                  
                  return Container(
                    width: 70,
                    margin: EdgeInsets.only(right: index < _weatherForecast.length - 1 ? 16 : 0),
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? Border.all(color: const Color(0xFF3B82F6), width: 1) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Today' : _formatForecastDate(forecast.date),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            _getWeatherIcon(forecast.description),
                            size: 20,
                            color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${forecast.temperature.round()}°',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedSoilStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Soil Analysis',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSoilParameter('pH Level', '6.5', 'Good', Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSoilParameter('Moisture', '68%', 'Optimal', Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSoilParameter('Nitrogen', 'Medium', 'Fair', Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSoilParameter('Temperature', '24°C', 'Good', Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoilParameter(String title, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationsSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Recommendations',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to full recommendations screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdviceScreen(showBottomNav: true)),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rice Recommendation Card
          _buildCropRecommendationCard(
            cropName: 'Rice',
            profit: '₹45,000',
            yield: '4.2 tons/acre',
            sustain: '85%',
            isRecommended: true,
          ),
          
          const SizedBox(height: 12),
          
          // Wheat Recommendation Card
          _buildCropRecommendationCard(
            cropName: 'Wheat',
            profit: '₹38,000',
            yield: '3.8 tons/acre',
            sustain: '78%',
            isRecommended: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCropRecommendationCard({
    required String cropName,
    required String profit,
    required String yield,
    required String sustain,
    required bool isRecommended,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light green background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
      ),
      child: Row(
        children: [
          // Crop name section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  'Profit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Yield section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yield,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Yield',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Sustain section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sustain,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Sustain',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Recommended badge
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Recommended',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatForecastDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain')) return Icons.water_drop_outlined;
    if (desc.contains('cloud')) return Icons.cloud_outlined;
    if (desc.contains('sun') || desc.contains('clear')) return Icons.wb_sunny_outlined;
    if (desc.contains('storm')) return Icons.thunderstorm_outlined;
    if (desc.contains('snow')) return Icons.ac_unit_outlined;
    return Icons.wb_cloudy_outlined;
  }

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: Color(0xFF2E7D32)),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5722),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        onPressed: () {
          // TODO: Show notifications
        },
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          color: const Color(0xFF4CAF50),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to respective detail screens
          },
          child: Text(
            actionText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen(showBottomNav: true)),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomAppBar(
          height: 55,
          shape: const CircularNotchedRectangle(),
          notchMargin: 4,
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0, true),
                _buildNavItem(Icons.qr_code_scanner_outlined, 'Scan', 1, false),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(Icons.lightbulb_outline, 'Advice', 2, false),
                _buildNavItem(Icons.person_outline, 'Profile', 3, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}