import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Bainada Wholesale Deep Emerald Green
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryDark = Color(0xFF0E3812);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // Secondary Accent - Golden Amber / Mustard
  static const Color accent = Color(0xFFF57F17);
  static const Color accentLight = Color(0xFFFFF8E1);
  static const Color secondary = Color(0xFFE65100);

  // Background & Surfaces
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF5A6A80);
  static const Color textMuted = Color(0xFF8C9BAE);

  // Status Colors
  static const Color statusPending = Color(0xFFE65100);
  static const Color statusApproved = Color(0xFF1565C0);
  static const Color statusDispatched = Color(0xFF6A1B9A);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFC62828);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);
}

class AppConstants {
  static const String appName = "Bainada Brothers";
  static const String appTagline = "Wholesale Grocery & Kirana Supply";

  static const List<String> productCategories = [
    'All Categories',
    'Grains & Rice',
    'Pulses & Dals',
    'Edible Oils & Ghee',
    'Flours & Atta',
    'Spices & Masala',
    'Sugar & Jaggery',
    'Dry Fruits & Nuts',
    'Packaged Goods & Snacks',
    'Beverages & Tea',
    'Soaps & Detergents',
    'Salt & Condiments',
  ];

  static const List<String> packagingUnits = [
    'kg',
    'bag (50kg)',
    'bag (25kg)',
    'bag (10kg)',
    'cartoon (12 pcs)',
    'cartoon (24 pcs)',
    'cartoon (48 pcs)',
    'peti (15kg)',
    'peti (15L Tin)',
    'packet (1kg)',
    'liter (1L)',
    'box',
  ];

  static const List<String> productUnits = packagingUnits;

  static const List<double> gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
}
