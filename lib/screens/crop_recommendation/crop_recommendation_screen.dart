import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';

class CropRecommendationScreen extends StatefulWidget {
  final CropRecommendation recommendations;
  final Map<String, double> soilData;
  final Map<String, dynamic> weatherData;

  const CropRecommendationScreen({
    super.key,
    required this.recommendations,
    required this.soilData,
    required this.weatherData,
  });

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                icon: const Icon(
                  Icons.share,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                onPressed: _shareRecommendations,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Soil & Weather Summary
                _buildAnalysisSummary(),
                const SizedBox(height: 20),

                // Recommended Crops
                _buildRecommendedCrops(),
                const SizedBox(height: 20),

                // Detailed Guidelines
                _buildDetailedGuidelines(),
                const SizedBox(height: 20),

                // Action Button
                _buildActionButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'AI-powered analysis based on your soil data',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Soil Score',
            '${widget.recommendations.soilSuitability.overallScore}/100',
            Icons.eco,
            const Color(0xFF10B981),
            widget.recommendations.soilSuitability.overallScore >= 75
                ? 'Excellent'
                : widget.recommendations.soilSuitability.overallScore >= 50
                    ? 'Good'
                    : 'Needs Work',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Weather',
            '${widget.recommendations.weatherSuitability.score}/100',
            Icons.wb_sunny,
            const Color(0xFFF59E0B),
            widget.recommendations.weatherSuitability.score >= 75
                ? 'Ideal'
                : widget.recommendations.weatherSuitability.score >= 50
                    ? 'Suitable'
                    : 'Challenging',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCrops() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_florist,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Top Recommended Crops',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.recommendations.recommendedCrops.map((crop) => _buildCropCard(crop)).toList(),
        ],
      ),
    );
  }

  Widget _buildCropCard(RecommendedCrop crop) {
    final index = widget.recommendations.recommendedCrops.indexOf(crop);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: index == 0 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: index == 0 
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              crop.icon,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      crop.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getProfitabilityColor(crop.profitability).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${crop.suitabilityScore}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getProfitabilityColor(crop.profitability),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Season: ${crop.season}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Expected: ${crop.expectedYield}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Text(
            'Farming Guidelines',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildGuidelineSection(
            'Fertilization Plan',
            widget.recommendations.fertilizationPlan,
            Icons.science,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          
          _buildGuidelineSection(
            'Irrigation Schedule',
            widget.recommendations.irrigationSchedule,
            Icons.water_drop,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          
          _buildGuidelineSection(
            'Market Insights',
            widget.recommendations.marketInsights,
            Icons.trending_up,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineSection(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 18),
            const SizedBox(width: 8),
            Text(
              'Start Planning',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProfitabilityColor(String profitability) {
    switch (profitability.toLowerCase()) {
      case 'high':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _shareRecommendations() {
    HapticFeedback.lightImpact();
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share functionality coming soon!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}