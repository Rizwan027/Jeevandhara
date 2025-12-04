import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeevandhara/screens/home/home_screen.dart';
import 'package:jeevandhara/screens/scan/scan_screen.dart';

class AdviceScreen extends StatelessWidget {
  const AdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crops = [
      CropRecommendation(
        name: 'Rice',
        profit: '₹45,000',
        profitLabel: 'Profit',
        difficultyTag: 'Best',
        difficultyColor: const Color(0xFFE8F5E9),
        difficultyTextColor: const Color(0xFF2E7D32),
        riskTag: 'Medium',
        riskColor: const Color(0xFFFFF3E0),
        riskTextColor: const Color(0xFFEF6C00),
        yieldValue: '4.2 tons/acre',
        yieldLabel: 'Yield',
        sustainabilityValue: '85%',
        sustainabilityLabel: 'Sustainability',
        marketDemandPercent: 92,
      ),
      CropRecommendation(
        name: 'Wheat',
        profit: '₹38,000',
        profitLabel: 'Profit',
        difficultyTag: 'Easy',
        difficultyColor: const Color(0xFFE3F2FD),
        difficultyTextColor: const Color(0xFF1565C0),
        riskTag: null,
        riskColor: null,
        riskTextColor: null,
        yieldValue: '3.8 tons/acre',
        yieldLabel: 'Yield',
        sustainabilityValue: '78%',
        sustainabilityLabel: 'Sustainability',
        marketDemandPercent: 88,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0FFF4),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title and subtitle
                Text(
                  'Crop Advisory',
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best crops for your soil',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Recommendation card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Recommendation',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Based on your soil conditions, Rice is the best option',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Recommended Crops',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: crops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return CropCard(crop: crops[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    const currentIndex = 1; // Advice tab

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == currentIndex) return;

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        } else if (index == 3) {
          // TODO: Implement Chat screen navigation
        } else if (index == 4) {
          // TODO: Implement Settings screen navigation
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb),
          label: 'Advice',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

class CropRecommendation {
  final String name;
  final String profit;
  final String profitLabel;
  final String? difficultyTag;
  final Color? difficultyColor;
  final Color? difficultyTextColor;
  final String? riskTag;
  final Color? riskColor;
  final Color? riskTextColor;
  final String yieldValue;
  final String yieldLabel;
  final String sustainabilityValue;
  final String sustainabilityLabel;
  final int marketDemandPercent;

  CropRecommendation({
    required this.name,
    required this.profit,
    required this.profitLabel,
    required this.difficultyTag,
    required this.difficultyColor,
    required this.difficultyTextColor,
    required this.riskTag,
    required this.riskColor,
    required this.riskTextColor,
    required this.yieldValue,
    required this.yieldLabel,
    required this.sustainabilityValue,
    required this.sustainabilityLabel,
    required this.marketDemandPercent,
  });
}

class CropCard extends StatelessWidget {
  final CropRecommendation crop;

  const CropCard({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (crop.difficultyTag != null)
                          _buildTag(
                            text: crop.difficultyTag!,
                            background: crop.difficultyColor!,
                            textColor: crop.difficultyTextColor!,
                          ),
                        if (crop.riskTag != null) ...[
                          const SizedBox(width: 8),
                          _buildTag(
                            text: crop.riskTag!,
                            background: crop.riskColor!,
                            textColor: crop.riskTextColor!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    crop.profit,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    crop.profitLabel,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                value: crop.yieldValue,
                label: crop.yieldLabel,
              ),
              _buildMetric(
                value: crop.sustainabilityValue,
                label: crop.sustainabilityLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Market Demand',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE0E0E0),
                  ),
                  FractionallySizedBox(
                    widthFactor: crop.marketDemandPercent / 100,
                    child: Container(
                      color: const Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${crop.marketDemandPercent}%',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetric({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
