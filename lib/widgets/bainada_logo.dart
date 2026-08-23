import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BainadaBrandLogo extends StatelessWidget {
  final bool isDarkTheme;
  final bool isStacked;
  final bool showSubtext;
  final double emblemSize;
  final String? customSubtext;

  const BainadaBrandLogo({
    super.key,
    this.isDarkTheme = true,
    this.isStacked = false,
    this.showSubtext = true,
    this.emblemSize = 42.0,
    this.customSubtext,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDarkTheme ? Colors.white : AppColors.primaryDark;
    final subtextColor = isDarkTheme ? Colors.white70 : AppColors.textSecondary;
    final subtext = customSubtext ?? 'WHOLESALE & KIRANA B2B';

    // Premium Wholesale Grocery Brand Emblem
    Widget emblem = Container(
      width: emblemSize,
      height: emblemSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32), // Emerald Forest Green
            Color(0xFF1B5E20), // Deep Forest Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(emblemSize * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF81C784).withAlpha(140),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Store / Grocery icon
          Icon(
            Icons.storefront_rounded,
            size: emblemSize * 0.56,
            color: Colors.white,
          ),
          // Verified wholesale badge
          Positioned(
            right: emblemSize * 0.05,
            bottom: emblemSize * 0.05,
            child: Container(
              padding: EdgeInsets.all(emblemSize * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000), // Amber Wholesale Badge
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Icon(
                Icons.check_rounded,
                size: emblemSize * 0.22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    Widget textBlock = Column(
      crossAxisAlignment:
          isStacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: isStacked ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BAINADA ',
                style: TextStyle(
                  fontSize: isStacked ? 22 : 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'BROTHERS',
                style: TextStyle(
                  fontSize: isStacked ? 22 : 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4CAF50), // Vibrant Green
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (showSubtext) ...[
          SizedBox(height: isStacked ? 4 : 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isStacked ? 11 : 9.5,
              fontWeight: FontWeight.w700,
              color: subtextColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );

    if (isStacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          const SizedBox(height: 12),
          textBlock,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        const SizedBox(width: 12),
        Flexible(child: textBlock),
      ],
    );
  }
}
