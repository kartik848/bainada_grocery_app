import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/ignito_branding.dart';
import 'auth_wrapper.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  void _openRoleLoginSheet(BuildContext context, UserRole role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoleLoginBottomSheet(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 960 : 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Official Vector Brand Logo Header
                  const BainadaBrandLogo(
                    isDarkTheme: false,
                    isStacked: true,
                    emblemSize: 56,
                    showSubtext: true,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: const Text(
                      'Choose Your Wholesale App Portal',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Big Role Cards
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRoleCard(
                            context: context,
                            role: UserRole.merchant,
                            title: 'Kirana Merchant',
                            hindiTitle: 'दुकानदार',
                            badge: '🛒 Store Ordering',
                            description:
                                'Order bulk grocery & staples at wholesale rates, track deliveries, view GST invoices & Khata ledger.',
                            color: const Color(0xFF1B5E20),
                            icon: Icons.storefront_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildRoleCard(
                            context: context,
                            role: UserRole.salesman,
                            title: 'Field Salesman',
                            hindiTitle: 'फील्ड सेल्समैन',
                            badge: '💼 Beat & Booking',
                            description:
                                'Onboard new Kirana stores, book orders on behalf of merchants, record cash payments & track commissions.',
                            color: const Color(0xFFE65100),
                            icon: Icons.badge_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildRoleCard(
                            context: context,
                            role: UserRole.deliveryBoy,
                            title: 'Delivery Partner',
                            hindiTitle: 'डिलीवरी साथी',
                            badge: '🚚 Dispatch & Drops',
                            description:
                                'View assigned route deliveries, 1-tap call to merchants, record COD cash collections & complete drops.',
                            color: const Color(0xFF4A148C),
                            icon: Icons.local_shipping_rounded,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRoleCard(
                          context: context,
                          role: UserRole.merchant,
                          title: 'Kirana Merchant',
                          hindiTitle: 'दुकानदार',
                          badge: '🛒 Store Ordering',
                          description:
                              'Order bulk grocery & staples at wholesale rates, track deliveries, view GST invoices & Khata ledger.',
                          color: const Color(0xFF1B5E20),
                          icon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildRoleCard(
                          context: context,
                          role: UserRole.salesman,
                          title: 'Field Salesman',
                          hindiTitle: 'फील्ड सेल्समैन',
                          badge: '💼 Beat & Booking',
                          description:
                              'Onboard new Kirana stores, book orders on behalf of merchants, record cash payments & track commissions.',
                          color: const Color(0xFFE65100),
                          icon: Icons.badge_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildRoleCard(
                          context: context,
                          role: UserRole.deliveryBoy,
                          title: 'Delivery Partner',
                          hindiTitle: 'डिलीवरी साथी',
                          badge: '🚚 Dispatch & Drops',
                          description:
                              'View assigned route deliveries, 1-tap call to merchants, record COD cash collections & complete drops.',
                          color: const Color(0xFF4A148C),
                          icon: Icons.local_shipping_rounded,
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Developer Branding Footer
                  const IgnitoCorpBranding(
                    isDarkTheme: false,
                    isCompact: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required UserRole role,
    required String title,
    required String hindiTitle,
    required String badge,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title with Hindi subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($hindiTitle)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions: Role Login & 1-Click Quick Demo
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openRoleLoginSheet(context, role),
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Sign In with Email / Mobile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleLoginBottomSheet extends StatefulWidget {
  final UserRole role;

  const _RoleLoginBottomSheet({required this.role});

  @override
  State<_RoleLoginBottomSheet> createState() => _RoleLoginBottomSheetState();
}

class _RoleLoginBottomSheetState extends State<_RoleLoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    try {
      final success = await auth.login(email, pass);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        if (auth.currentUserModel != null && !auth.currentUserModel!.isActive) {
          await auth.logout();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account is deactivated. Contact Bainada Brothers Admin.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.pop(context); // Close sheet

        // Clean navigation through AuthWrapper root
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Invalid login credentials.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    Color roleColor;
    String roleName;

    switch (role) {
      case UserRole.merchant:
        roleColor = const Color(0xFF1B5E20);
        roleName = 'Kirana Merchant Portal';
        break;
      case UserRole.salesman:
        roleColor = const Color(0xFFE65100);
        roleName = 'Field Salesman Portal';
        break;
      case UserRole.deliveryBoy:
        roleColor = const Color(0xFF4A148C);
        roleName = 'Delivery Partner Portal';
        break;
      case UserRole.admin:
        roleColor = AppColors.primary;
        roleName = 'Admin Portal';
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: roleColor.withAlpha(30),
                    child: Icon(Icons.lock_person_rounded, color: roleColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    roleName,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: roleColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Enter your registered credentials to access your portal.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 18),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Registered Mobile or Email',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter mobile or email' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter password' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign In to $roleName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
