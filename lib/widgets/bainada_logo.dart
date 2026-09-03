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
        borderRadius: BorderRadius.circular(emblemSize * 0.26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(emblemSize * 0.26),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: emblemSize,
          height: emblemSize,
          fit: BoxFit.contain,
        ),
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
