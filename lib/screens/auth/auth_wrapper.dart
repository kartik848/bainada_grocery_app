import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/ignito_branding.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_web_dashboard.dart';
import '../delivery/delivery_dashboard.dart';
import '../merchant/merchant_dashboard.dart';
import '../salesman/salesman_dashboard.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _forceTimeout = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Safety fallback: Maximum 1.8 seconds on loading screen
    _timeoutTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && !_forceTimeout) {
        setState(() => _forceTimeout = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 1. Web Platform: Check Admin Authentication
        if (kIsWeb) {
          if (auth.isLoading && !_forceTimeout) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D2818),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BainadaBrandLogo(
                      isDarkTheme: true,
                      isStacked: true,
                      emblemSize: 64,
                      showSubtext: true,
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!auth.isAuthenticated || auth.currentUserModel == null) {
            return const LoginScreen();
          }

          // On Web Admin sessions, always route directly to AdminWebDashboard portal
          return const AdminWebDashboard();
        }

        // 2. Loading State on Mobile with 1.8s safety timeout guard
        if (auth.isLoading && !_forceTimeout) {
          return const Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BainadaBrandLogo(
                    isDarkTheme: true,
                    isStacked: true,
                    emblemSize: 64,
                    showSubtext: true,
                  ),
                  SizedBox(height: 36),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 32),
                  IgnitoCorpBranding(
                    isDarkTheme: true,
                    isCompact: false,
                  ),
                ],
              ),
            ),
          );
        }

        // 3. Mobile Native App -> Multi-Role Selection
        if (!auth.isAuthenticated || auth.currentUserModel == null) {
          return const RoleSelectScreen();
        }

        final role = auth.userRole ?? UserRole.merchant;

        // 4. Mobile Layout routing
        switch (role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.salesman:
            return const SalesmanDashboard();
          case UserRole.deliveryBoy:
            return const DeliveryDashboard();
          case UserRole.merchant:
            return const MerchantDashboard();
        }
      },
    );
  }
}
