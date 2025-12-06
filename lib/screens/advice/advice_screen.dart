import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jeevandhara/screens/chat/chat_screen.dart';

class AdviceScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const AdviceScreen({super.key, this.showBottomNav = true});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'Crops';
  int _selectedSeason = 0; // 0: Current, 1: Next, 2: Year-round

  final List<String> _seasons = ['Current Season', 'Next Season', 'Year-round'];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Crops', 'icon': FontAwesomeIcons.seedling},
    {'name': 'Tips', 'icon': FontAwesomeIcons.lightbulb},
    {'name': 'Weather', 'icon': FontAwesomeIcons.cloudSun},
    {'name': 'Market', 'icon': FontAwesomeIcons.chartLine},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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

  List<CropRecommendation> get _filteredCrops {
    final baseCrops = [
      CropRecommendation(
        name: 'Rice',
        profit: '₹45,000',
        profitLabel: 'Expected profit/acre',
        difficultyTag: 'Recommended',
        difficultyColor: const Color(0xFFE8F5E9),
        difficultyTextColor: const Color(0xFF2E7D32),
        riskTag: 'Low Risk',
        riskColor: const Color(0xFFE8F5E9),
        riskTextColor: const Color(0xFF2E7D32),
        yieldValue: '4.2 tons/acre',
        yieldLabel: 'Average yield',
        sustainabilityValue: '85%',
        sustainabilityLabel: 'Water efficiency',
        marketDemandPercent: 92,
        season: 'Monsoon',
        plantingTime: 'June - July',
        harvestTime: 'November - December',
        soilType: 'Clay, Loamy',
        waterRequirement: 'High',
      ),
      CropRecommendation(
        name: 'Wheat',
        profit: '₹38,000',
        profitLabel: 'Expected profit/acre',
        difficultyTag: 'Good Choice',
        difficultyColor: const Color(0xFFFFF3E0),
        difficultyTextColor: const Color(0xFFEF6C00),
        riskTag: 'Medium Risk',
        riskColor: const Color(0xFFFFF3E0),
        riskTextColor: const Color(0xFFEF6C00),
        yieldValue: '3.8 tons/acre',
        yieldLabel: 'Average yield',
        sustainabilityValue: '78%',
        sustainabilityLabel: 'Water efficiency',
        marketDemandPercent: 88,
        season: 'Winter',
        plantingTime: 'November - December',
        harvestTime: 'April - May',
        soilType: 'Loamy, Sandy',
        waterRequirement: 'Medium',
      ),
    ];

    if (_selectedSeason == 0) {
      return baseCrops.where((crop) => crop.season == 'Monsoon').toList();
    } else if (_selectedSeason == 1) {
      return baseCrops.where((crop) => crop.season == 'Winter').toList();
    } else {
      return baseCrops;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      const Color(0xFF81C784).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (widget.showBottomNav)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        if (!widget.showBottomNav)
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.lightbulb,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Smart Advisory',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                'AI-powered farming insights',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatScreen(showBottomNav: true),
                              ),
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.robot,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category Tabs and Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: _buildCategoryTabs(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_selectedCategory == 'Crops') ...[
                    _buildSeasonFilter(),
                    const SizedBox(height: 24),
                    _buildCropsList(),
                  ] else if (_selectedCategory == 'Tips') ...[
                    _buildFarmingTips(),
                  ] else if (_selectedCategory == 'Weather') ...[
                    _buildWeatherInsights(),
                  ] else if (_selectedCategory == 'Market') ...[
                    _buildMarketInsights(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children: _categories.map((category) {
        final isSelected = category['name'] == _selectedCategory;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  FaIcon(
                    category['icon'],
                    color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Season',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_seasons.length, (index) {
            final isSelected = index == _selectedSeason;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSeason = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _seasons.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    _seasons[index],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCropsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Crops',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredCrops.map(
          (crop) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildModernCropCard(crop),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCropCard(CropRecommendation crop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: crop.difficultyColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.seedling,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    crop.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: crop.difficultyColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  crop.difficultyTag,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: crop.difficultyTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Profit',
                  crop.profit,
                  FontAwesomeIcons.indianRupeeSign,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Yield',
                  crop.yieldValue,
                  FontAwesomeIcons.chartLine,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Water',
                  crop.waterRequirement,
                  FontAwesomeIcons.droplet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planting: ${crop.plantingTime}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Harvest: ${crop.harvestTime}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Learn More',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, size: 16, color: const Color(0xFF4CAF50)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFarmingTips() {
    final tips = [
      {
        'title': 'Soil Preparation',
        'desc': 'Test soil pH before planting',
        'icon': FontAwesomeIcons.seedling,
      },
      {
        'title': 'Water Management',
        'desc': 'Install drip irrigation system',
        'icon': FontAwesomeIcons.droplet,
      },
      {
        'title': 'Pest Control',
        'desc': 'Use integrated pest management',
        'icon': FontAwesomeIcons.bug,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      tip['icon'] as IconData,
                      color: const Color(0xFF4CAF50),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tip['desc'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeatherInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.cloudSun,
                color: Color(0xFFFF9800),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weather Forecast',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Moderate rain expected this week. Good for rice transplantation.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.chartLine,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Market Trends',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rice prices up 8%. Wheat demand steady. Good selling opportunity.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class CropRecommendation {
  final String name;
  final String profit;
  final String profitLabel;
  final String difficultyTag;
  final Color difficultyColor;
  final Color difficultyTextColor;
  final String? riskTag;
  final Color? riskColor;
  final Color? riskTextColor;
  final String yieldValue;
  final String yieldLabel;
  final String sustainabilityValue;
  final String sustainabilityLabel;
  final int marketDemandPercent;
  final String season;
  final String plantingTime;
  final String harvestTime;
  final String soilType;
  final String waterRequirement;

  CropRecommendation({
    required this.name,
    required this.profit,
    required this.profitLabel,
    required this.difficultyTag,
    required this.difficultyColor,
    required this.difficultyTextColor,
    this.riskTag,
    this.riskColor,
    this.riskTextColor,
    required this.yieldValue,
    required this.yieldLabel,
    required this.sustainabilityValue,
    required this.sustainabilityLabel,
    required this.marketDemandPercent,
    required this.season,
    required this.plantingTime,
    required this.harvestTime,
    required this.soilType,
    required this.waterRequirement,
  });
}
