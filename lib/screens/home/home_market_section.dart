import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../localization/app_localizations.dart';
import '../../services/market_data_service.dart';

class HomeMarketSection extends StatelessWidget {
  final List<MarketPrice> marketPrices;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onViewAnalysis;

  const HomeMarketSection({
    super.key,
    required this.marketPrices,
    required this.isLoading,
    required this.hasError,
    required this.onViewAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-market-section'),
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
                  Icons.show_chart,
                  color: Color(0xFF059669),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Market prices',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            _buildStateMessage(Icons.sync, 'Loading market prices...')
          else if (hasError)
            _buildStateMessage(
              Icons.cloud_off,
              'Market prices are currently unavailable.',
            )
          else if (marketPrices.isEmpty)
            _buildStateMessage(
              Icons.inbox_outlined,
              'No market prices available.',
            )
          else
            Column(children: marketPrices.map(_buildMarketPriceCard).toList()),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onViewAnalysis,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insights, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.getText('view_detailed_analysis'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPriceCard(MarketPrice price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    price.commodity,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  '₹${price.modalPrice.toStringAsFixed(0)}/qtl',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${price.market}, ${price.state}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF374151),
              ),
            ),
            Text(
              'Arrival: ${_formatDate(price.priceDate)}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF6B7280),
              ),
            ),
            Text(
              price.source,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateMessage(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
