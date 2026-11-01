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
    final localization = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('home-market-section'),
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
                  Icons.show_chart,
                  color: Color(0xFF287A45),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localization.getText('home_market_title'),
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
          if (isLoading)
            _buildStateMessage(
              Icons.sync,
              localization.getText('home_market_loading'),
              color: const Color(0xFF287A45),
            )
          else if (hasError)
            _buildStateMessage(
              Icons.cloud_off,
              localization.getText('home_market_unavailable'),
              color: const Color(0xFF9A6B18),
            )
          else if (marketPrices.isEmpty)
            _buildStateMessage(
              Icons.inbox_outlined,
              localization.getText('home_market_empty'),
              color: const Color(0xFF6B8F3E),
            )
          else
            Column(
              children: marketPrices
                  .map((price) => _buildMarketPriceCard(context, price))
                  .toList(),
            ),
          const SizedBox(height: 10),
          Material(
            color: const Color(0xFF287A45),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onViewAnalysis,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insights, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          localization.getText('view_detailed_analysis'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPriceCard(BuildContext context, MarketPrice price) {
    final localization = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EBDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 300;
                final commodity = Text(
                  price.commodity,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF183B27),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                final priceText = Text(
                  '₹${price.modalPrice.toStringAsFixed(0)}/qtl',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF287A45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          commodity,
                          const SizedBox(height: 4),
                          priceText,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: commodity),
                          const SizedBox(width: 8),
                          Flexible(child: priceText),
                        ],
                      );
              },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF6B8F3E),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${price.market}, ${price.state}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF455B49),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              localization
                  .getText('home_market_arrival')
                  .replaceAll('{date}', _formatDate(price.priceDate)),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF657467),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              price.source,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF657467),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateMessage(
    IconData icon,
    String message, {
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EBDD)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.35,
                color: const Color(0xFF526456),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
