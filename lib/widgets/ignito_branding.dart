import 'package:flutter/material.dart';

class IgnitoCorpBranding extends StatelessWidget {
  final bool isDarkTheme;
  final bool isCompact;

  const IgnitoCorpBranding({
    super.key,
    this.isDarkTheme = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white60 : const Color(0xFF64748B);
    final highlightColor = isDarkTheme ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ignito Logo with graceful error fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/ignito_logo.png',
              height: isCompact ? 16 : 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isCompact ? 10.5 : 11.5,
                color: textColor,
                letterSpacing: 0.3,
                fontFamily: 'Roboto',
              ),
              children: [
                TextSpan(text: isCompact ? 'By ' : 'Developed & Managed by '),
                TextSpan(
                  text: 'IGNITOCORP',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: highlightColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
