import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/ignito_branding.dart';
import '../auth/auth_wrapper.dart';
import 'admin_web_dashboard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // If running on Web or Desktop screen, render the dedicated Web Admin Panel
    if (kIsWeb) {
      return const AdminWebDashboard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 850) {
          return const AdminWebDashboard();
        }
        return _buildMobileWebOnlyNotice(context);
      },
    );
  }

  Widget _buildMobileWebOnlyNotice(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BainadaBrandLogo(
                  isDarkTheme: true,
                  isStacked: true,
                  emblemSize: 64,
                  showSubtext: true,
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.laptop_mac_rounded,
                          size: 48,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Admin Web Portal Only',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D2818),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'एडमिन पैनल केवल वेब पोर्टल पर उपलब्ध है',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'नमस्ते ${user?.name ?? 'Admin'}, Bainada Brothers Admin Panel केवल कंप्यूटर/लैपटॉप वेब ब्राउज़र पर संचालित होता है। मोबाइल ऐप केवल व्यापारी (Merchant), फील्ड सेल्समैन और डिलीवरी पार्टनर्स के लिए है।',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(
                                'https://bainada-admin-portal.vercel.app');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_browser_rounded,
                              size: 20),
                          label: const Text(
                            'Open Web Admin Portal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthWrapper()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'लॉगआउट करें (Sign Out)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const IgnitoCorpBranding(
                  isDarkTheme: true,
                  isCompact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
