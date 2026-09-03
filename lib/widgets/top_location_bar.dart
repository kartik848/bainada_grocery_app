import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class TopLocationBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final bool isCompact;

  const TopLocationBar({
    super.key,
    this.backgroundColor = Colors.white,
    this.textColor = AppColors.textPrimary,
    this.isCompact = false,
  });

  void _showLocationDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<LocationProvider>(
        builder: (context, loc, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'आपकी वर्तमान लोकेशन (Live GPS)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              loc.currentLocality,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (loc.currentAddress != null && loc.currentAddress!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          loc.currentAddress!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                      ],
                      if (loc.latitude != null && loc.longitude != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'GPS Coordinates: ${loc.latitude!.toStringAsFixed(5)}, ${loc.longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loc.isLoading
                            ? null
                            : () async {
                                await loc.refreshLocation();
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('लाइव GPS लोकेशन अपडेट हो गई!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                        icon: loc.isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('लोकेशन रिफ्रेश करें (GPS Re-fetch)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (loc.latitude != null && loc.longitude != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          LocationService.openGoogleMapsNavigation(
                            destinationLat: loc.latitude!,
                            destinationLng: loc.longitude!,
                          );
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('मैप देखें'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, loc, _) {
        return InkWell(
          onTap: () => _showLocationDetailsSheet(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor.withAlpha(backgroundColor == Colors.white ? 255 : 35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  loc.isLoading ? Icons.hourglass_top_rounded : Icons.location_on_rounded,
                  size: 15,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    loc.isLoading ? 'Detecting GPS...' : loc.currentLocality,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textColor.withAlpha(200)),
              ],
            ),
          ),
        );
      },
    );
  }
}
