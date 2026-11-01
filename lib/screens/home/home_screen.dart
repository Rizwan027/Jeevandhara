import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../advice/advice_screen.dart';
import '../chat/chat_screen.dart';
import '../input_data/input_data_screen.dart';
import 'home_market_section.dart';
import '../../services/weather_service.dart';
import '../../services/ai_service.dart';
import '../../services/market_data_service.dart';
import '../../services/soil_data_service.dart';
import '../../localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueNotifier<List<String>>? recommendationNotifier;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.recommendationNotifier,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late WeatherService _weatherService;
  late AIService _aiService;
  late MarketDataService _marketDataService;

  WeatherData? _currentWeather;
  List<WeatherAlert> _weatherAlerts = [];
  List<WeatherForecast> _weatherForecast = [];
  bool _isLoadingWeather = true;
  bool _weatherIsStale = false;
  int _weatherRequestId = 0;
  List<MarketPrice> _marketPrices = [];
  bool _isLoadingMarket = true;
  bool _marketHasError = false;
  int _marketRequestId = 0;
  List<String>? _lastRequestedCommodities;

  Map<String, double>? _soilData;
  bool _isLoadingSoil = true;

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService();
    _aiService = AIService();
    _marketDataService = MarketDataService();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Load weather, market, and soil data
    _loadWeatherData();
    _loadMarketData();
    _loadSoilData();
    widget.recommendationNotifier?.addListener(_onRecommendationsChanged);
  }

  Future<void> _loadSoilData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _soilData = null;
            _isLoadingSoil = false;
          });
        }
        return;
      }
      final data = await SoilDataService.getSoilData(userId: user.uid);
      if (mounted) {
        setState(() {
          _soilData = data;
          _isLoadingSoil = false;
        });
      }
    } catch (e) {
      developer.log('Error loading soil data', error: e, name: 'HomeScreen');
      if (mounted) {
        setState(() {
          _isLoadingSoil = false;
        });
      }
    }
  }

  void _onRecommendationsChanged() {
    final commodities = widget.recommendationNotifier!.value
        .map((crop) => crop.trim())
        .where((crop) => crop.isNotEmpty)
        .toList(growable: false);
    if (commodities.isEmpty ||
        _sameCommodityList(_lastRequestedCommodities, commodities)) {
      return;
    }
    _lastRequestedCommodities = commodities;
    _loadMarketData(commodities: commodities);
  }

  bool _sameCommodityList(List<String>? first, List<String> second) {
    if (first == null || first.length != second.length) return false;
    for (var index = 0; index < second.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  Future<void> _loadWeatherData() async {
    final requestId = ++_weatherRequestId;
    try {
      final weather = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getWeatherForecast();

      if (weather != null) {
        final alerts = _weatherService.generateFarmingAlerts(weather, forecast);

        if (mounted && requestId == _weatherRequestId) {
          setState(() {
            _currentWeather = weather;
            _weatherForecast = forecast;
            _weatherAlerts = alerts;
            _isLoadingWeather = false;
            _weatherIsStale = false;
          });
        }
      } else if (mounted && requestId == _weatherRequestId) {
        final cached = await _weatherService.getCachedWeather();
        if (!mounted || requestId != _weatherRequestId) return;
        setState(() {
          _currentWeather = cached?.weather;
          _weatherForecast = cached?.forecast ?? forecast;
          _weatherAlerts = cached == null
              ? []
              : _weatherService.generateFarmingAlerts(
                  cached.weather,
                  cached.forecast,
                );
          _isLoadingWeather = false;
          _weatherIsStale = cached?.isStale ?? false;
        });
      }
    } catch (e) {
      developer.log('Error loading weather', error: e, name: 'HomeScreen');
      if (mounted && requestId == _weatherRequestId) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _loadMarketData({List<String>? commodities}) async {
    final requestId = ++_marketRequestId;
    if (mounted) {
      setState(() {
        _isLoadingMarket = true;
        _marketHasError = false;
      });
    }
    try {
      final prices = await _marketDataService.fetchDailyPrices(
        commodities: commodities,
      );
      if (!mounted || requestId != _marketRequestId) return;
      setState(() {
        _marketPrices = prices;
        _isLoadingMarket = false;
        _marketHasError = false;
      });
    } catch (error) {
      developer.log(
        'Error loading market data',
        error: error,
        name: 'HomeScreen',
      );
      if (!mounted || requestId != _marketRequestId) return;
      final hasExistingPrices = _marketPrices.isNotEmpty;
      setState(() {
        if (!hasExistingPrices) _marketPrices = [];
        _isLoadingMarket = false;
        _marketHasError = !hasExistingPrices;
      });
    }
  }

  @override
  void dispose() {
    widget.recommendationNotifier?.removeListener(_onRecommendationsChanged);
    _animationController.dispose();
    super.dispose();
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
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0FDF4), Color(0xFFE8F5E9)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCEFE0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 340;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTimeOfDay(context),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF52705B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.getText('hello_farmer'),
                                    style: GoogleFonts.inter(
                                      fontSize: isNarrow ? 22 : 26,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                      color: const Color(0xFF183B27),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Keep these as visual controls; they have no actions today.
                            Semantics(
                              label: AppLocalizations.of(
                                context,
                              )!.getText('home_notifications'),
                              button: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFD5E7D9),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Color(0xFF42634B),
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF287A45),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF287A45,
                                          ).withValues(alpha: 0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
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
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.getText('todays_alerts'),
                    ),
                    const SizedBox(height: 16),
                    _buildAlertCards(),

                    const SizedBox(height: 32),

                    // Soil Status Section
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.getText('soil_status'),
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedSoilStatusCard(),

                    const SizedBox(height: 32),

                    // Weather Forecast Section
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.getText('weather_forecast'),
                    ),
                    const SizedBox(height: 16),
                    _buildWeatherForecastCard(),

                    const SizedBox(height: 32),

                    // Sample market prices are clearly labeled in the section.
                    _buildSectionTitle(
                      AppLocalizations.of(
                        context,
                      )!.getText('live_market_prices'),
                    ),
                    const SizedBox(height: 16),
                    HomeMarketSection(
                      marketPrices: _marketPrices,
                      isLoading: _isLoadingMarket,
                      hasError: _marketHasError,
                      onViewAnalysis: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdviceScreen(
                              showBottomNav: true,
                              recommendationNotifier:
                                  widget.recommendationNotifier,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Navigation is owned by MainNavigation.
    );
  }

  // Helper method for time-based greeting
  String _getTimeOfDay(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.getText('good_morning');
    if (hour < 17) {
      return AppLocalizations.of(context)!.getText('good_afternoon');
    }
    return AppLocalizations.of(context)!.getText('good_evening');
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            AppLocalizations.of(context)!.getText('crop_advice'),
            Icons.eco_outlined,
            const Color(0xFF287A45),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdviceScreen(
                  showBottomNav: true,
                  recommendationNotifier: widget.recommendationNotifier,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            AppLocalizations.of(context)!.getText('add_data'),
            Icons.add_circle_outline,
            const Color(0xFF6B8F3E),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InputDataScreen()),
            ).then((_) => _loadSoilData()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCEFE0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF315D3E).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24442E),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    alertWidgets.add(
      _buildAlertCard(
        AppLocalizations.of(context)!.getText('rice_price_alert'),
        AppLocalizations.of(context)!.getText('rice_price_desc'),
        Icons.trending_up_outlined,
        const Color(0xFFF59E0B),
      ),
    );

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
          width: alert.severity == AlertSeverity.urgent ? 2 : 1,
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
              child: Text(alert.icon, style: const TextStyle(fontSize: 20)),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.getText('urgent'),
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
            Icon(Icons.chevron_right, color: alertColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
                        AppLocalizations.of(context)!.getText('ph_level'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.getText('optimal_crops'),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCEFE0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEFE0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315D3E).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Color(0xFF287A45),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.getText('weather_forecast'),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF183B27),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_weatherIsStale)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message: AppLocalizations.of(
                      context,
                    )!.getText('home_cached_weather'),
                    child: const Icon(
                      Icons.history,
                      size: 20,
                      color: Color(0xFF9A6B18),
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: AppLocalizations.of(
                  context,
                )!.getText('home_refresh_weather'),
                onPressed: _isLoadingWeather
                    ? null
                    : () {
                        setState(() => _isLoadingWeather = true);
                        _loadWeatherData();
                      },
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF287A45),
                  backgroundColor: const Color(0xFFF0F7F1),
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.refresh, size: 21),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Current Weather Information
          if (_currentWeather != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F9F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.getText('current_weather'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF52705B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentWeather!.cityName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_currentWeather!.temperature.round()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      color: const Color(0xFF183B27),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '°C',
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF52705B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.getText('temperature'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 54,
                        color: const Color(0xFFDCE8D9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getWeatherIcon(_currentWeather!.description),
                                size: 21,
                                color: const Color(0xFF6B8F3E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentWeather!.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: const Color(0xFF24442E),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 16,
                          color: Color(0xFF6B8F3E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentWeather!.humidity}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF24442E),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context)!.getText('humidity'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          // 5-Day Forecast
          if (_weatherForecast.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.getText('five_day_forecast'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF24442E),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weatherForecast.length,
                itemBuilder: (context, index) {
                  final forecast = _weatherForecast[index];
                  final isToday = index == 0;

                  return Container(
                    width: 76,
                    margin: EdgeInsets.only(
                      right: index < _weatherForecast.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(14),
                      border: isToday
                          ? Border.all(color: const Color(0xFFB7D7BC), width: 1)
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday
                                ? AppLocalizations.of(context)!.getText('today')
                                : _formatForecastDate(forecast.date),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isToday
                                  ? const Color(0xFF287A45)
                                  : const Color(0xFF6B7280),
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            _getWeatherIcon(forecast.description),
                            size: 19,
                            color: isToday
                                ? const Color(0xFF287A45)
                                : const Color(0xFF7C8B7D),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${forecast.temperature.round()}°',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? const Color(0xFF287A45)
                                  : const Color(0xFF24442E),
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
          if (_currentWeather == null && _weatherForecast.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(
                  context,
                )!.getText('home_weather_unavailable'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSoilStatusCard() {
    if (_isLoadingSoil) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCEFE0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (_soilData == null || _soilData!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCEFE0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF315D3E).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: Color(0xFF287A45),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.getText('soil_analysis'),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF183B27),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.getText('home_no_soil_data'),
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InputDataScreen(),
                    ),
                  ).then((_) => _loadSoilData());
                },
                icon: const Icon(Icons.add_circle_outline, size: 19),
                label: Text(
                  AppLocalizations.of(context)!.getText('home_add_soil_data'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF287A45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ph = _soilData!['ph'];
    final n = _soilData!['nitrogen'];
    final p = _soilData!['phosphorus'];
    final k = _soilData!['potassium'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEFE0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315D3E).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF287A45),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.getText('soil_analysis'),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF183B27),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth < 260 ? 1 : 2;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final localization = AppLocalizations.of(context)!;
              final parameters = [
                (
                  localization.getText('ph_level_short'),
                  ph != null ? ph.toStringAsFixed(1) : '--',
                  ph != null && ph >= 6.0 && ph <= 7.5
                      ? localization.getText('optimal')
                      : localization.getText('home_saved_status'),
                ),
                (
                  localization.getText('nitrogen'),
                  n != null ? n.toStringAsFixed(0) : '--',
                  localization.getText('home_saved_status'),
                ),
                (
                  localization.getText('home_phosphorus'),
                  p != null ? p.toStringAsFixed(0) : '--',
                  localization.getText('home_saved_status'),
                ),
                (
                  localization.getText('home_potassium'),
                  k != null ? k.toStringAsFixed(0) : '--',
                  localization.getText('home_saved_status'),
                ),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final (title, value, status) in parameters)
                    SizedBox(
                      width: itemWidth,
                      child: _buildSoilParameter(title, value, status),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSoilParameter(String title, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EBDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.25,
              color: const Color(0xFF52705B),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF183B27),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.25,
              color: const Color(0xFF6B8F3E),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTrendsSection() {
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
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.getText('home_market_trends'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to full recommendations screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdviceScreen(
                        showBottomNav: true,
                        recommendationNotifier: widget.recommendationNotifier,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.getText('home_view_all'),
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
      padding: const EdgeInsets.all(12),
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
                  AppLocalizations.of(context)!.getText('home_profit'),
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
                  AppLocalizations.of(context)!.getText('home_yield'),
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
                  AppLocalizations.of(context)!.getText('home_sustainability'),
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
                AppLocalizations.of(context)!.getText('home_recommended'),
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
    const weekdayKeys = [
      'home_weekday_mon',
      'home_weekday_tue',
      'home_weekday_wed',
      'home_weekday_thu',
      'home_weekday_fri',
      'home_weekday_sat',
      'home_weekday_sun',
    ];
    return AppLocalizations.of(context)!.getText(weekdayKeys[date.weekday - 1]);
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain')) return Icons.water_drop_outlined;
    if (desc.contains('cloud')) return Icons.cloud_outlined;
    if (desc.contains('sun') || desc.contains('clear')) {
      return Icons.wb_sunny_outlined;
    }
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
          child: const Icon(Icons.person, color: Colors.white, size: 24),
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
            MaterialPageRoute(
              builder: (context) => const ChatScreen(showBottomNav: true),
            ),
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
}
