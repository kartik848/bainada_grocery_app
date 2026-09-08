import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/animated_3d_icons.dart';
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
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1040 : 480),
            child: isDesktop
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(isDesktop: true),
                        const SizedBox(height: 20),
                        _buildInstructionPill(),
                        const SizedBox(height: 20),
                        _buildDesktopRoleCards(context),
                        const SizedBox(height: 24),
                        const IgnitoCorpBranding(isDarkTheme: false, isCompact: false),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. Prominent Brand Header
                                  _buildHeader(isDesktop: false),

                                  const SizedBox(height: 14),

                                  // 2. Portal Selection Pill
                                  Center(child: _buildInstructionPill()),

                                  const SizedBox(height: 14),

                                  // 3. The 3 Role Cards
                                  _buildRoleTileMobile(
                                    context: context,
                                    role: UserRole.merchant,
                                    title: 'Kirana Merchant',
                                    hindiTitle: 'दुकानदार पोर्टल',
                                    badge: 'थोक किराना व राशन सामान',
                                    color: const Color(0xFF1B5E20),
                                    iconWidget: Animated3DMerchantIcon(
                                      size: 64,
                                      onTap: () => _openRoleLoginSheet(context, UserRole.merchant),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRoleTileMobile(
                                    context: context,
                                    role: UserRole.salesman,
                                    title: 'Field Salesman',
                                    hindiTitle: 'फील्ड सेल्समैन पोर्टल',
                                    badge: 'दुकान ऑनबोर्डिंग व बुकिंग',
                                    color: const Color(0xFFE65100),
                                    iconWidget: Animated3DSalesmanIcon(
                                      size: 64,
                                      onTap: () => _openRoleLoginSheet(context, UserRole.salesman),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRoleTileMobile(
                                    context: context,
                                    role: UserRole.deliveryBoy,
                                    title: 'Delivery Partner',
                                    hindiTitle: 'डिलीवरी साथी पोर्टल',
                                    badge: 'मैप नेविगेशन व COD कलेक्शन',
                                    color: const Color(0xFF4A148C),
                                    iconWidget: Animated3DDeliveryIcon(
                                      size: 64,
                                      onTap: () => _openRoleLoginSheet(context, UserRole.deliveryBoy),
                                    ),
                                  ),

                                  const Spacer(),

                                  // 4. Footer (No Admin Login)
                                  _buildMobileFooter(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: isDesktop ? 18 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D2818),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330D2818),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF81C784).withAlpha(80),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BainadaBrandLogo(
            isDarkTheme: true,
            isStacked: true,
            emblemSize: isDesktop ? 62 : 56,
            showSubtext: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFFFFD54F)),
                  SizedBox(width: 6),
                  Text(
                    'B2B WHOLESALE & DISTRIBUTION NETWORK',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
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

  Widget _buildInstructionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primary.withAlpha(35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 15, color: AppColors.primary),
          SizedBox(width: 6),
          Text(
            'अपना पोर्टल चुनें और लॉगिन करें',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTileMobile({
    required BuildContext context,
    required UserRole role,
    required String title,
    required String hindiTitle,
    required String badge,
    required Color color,
    required Widget iconWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRoleLoginSheet(context, role),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: Center(child: iconWidget),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hindiTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRoleCards(BuildContext context) {
    return Row(
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
                'थोक भाव में किराना और राशन मंगवाएं, डिलीवरी ट्रैक करें और खाता लेजर देखें।',
            color: const Color(0xFF1B5E20),
            iconWidget: Animated3DMerchantIcon(
              size: 88,
              onTap: () => _openRoleLoginSheet(context, UserRole.merchant),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRoleCard(
            context: context,
            role: UserRole.salesman,
            title: 'Field Salesman',
            hindiTitle: 'फील्ड सेल्समैन',
            badge: '💼 Beat & Booking',
            description:
                'नई दुकानें जोड़ें, व्यापारियों के लिए आर्डर बुक करें और कमीशन ट्रैक करें।',
            color: const Color(0xFFE65100),
            iconWidget: Animated3DSalesmanIcon(
              size: 88,
              onTap: () => _openRoleLoginSheet(context, UserRole.salesman),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRoleCard(
            context: context,
            role: UserRole.deliveryBoy,
            title: 'Delivery Partner',
            hindiTitle: 'डिलीवरी साथी',
            badge: '🚚 Dispatch & Drops',
            description:
                'रूट डिलीवरी देखें, व्यापारी को 1-टैप कॉल करें और कैश कलेक्शन सबमिट करें।',
            color: const Color(0xFF4A148C),
            iconWidget: Animated3DDeliveryIcon(
              size: 88,
              onTap: () => _openRoleLoginSheet(context, UserRole.deliveryBoy),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildMobileFooter(BuildContext context) {
    return const Center(
      child: IgnitoCorpBranding(
        isDarkTheme: false,
        isCompact: true,
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
    required Widget iconWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openRoleLoginSheet(context, role),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: 3D Animated Icon + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The 3D Animated Icon with glowing pedestal
                    iconWidget,
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withAlpha(50)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Role Title & Hindi Subtitle
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hindiTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button: Sign In
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _openRoleLoginSheet(context, role),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'लॉगिन करें / Sign In',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            content: Text(auth.errorMessage ?? 'Invalid login credentials. Please check mobile/email & password.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    Color roleColor;
    String roleName;
    String hindiRole;
    Widget role3DIcon;

    switch (role) {
      case UserRole.merchant:
        roleColor = const Color(0xFF1B5E20);
        roleName = 'Kirana Merchant Portal';
        hindiRole = 'दुकानदार पोर्टल';
        role3DIcon = const Animated3DMerchantIcon(size: 80);
        break;
      case UserRole.salesman:
        roleColor = const Color(0xFFE65100);
        roleName = 'Field Salesman Portal';
        hindiRole = 'फील्ड सेल्समैन पोर्टल';
        role3DIcon = const Animated3DSalesmanIcon(size: 80);
        break;
      case UserRole.deliveryBoy:
        roleColor = const Color(0xFF4A148C);
        roleName = 'Delivery Partner Portal';
        hindiRole = 'डिलीवरी साथी पोर्टल';
        role3DIcon = const Animated3DDeliveryIcon(size: 80);
        break;
      case UserRole.admin:
        roleColor = AppColors.primary;
        roleName = 'Master Admin Portal';
        hindiRole = 'मास्टर एडमिन पोर्टल';
        role3DIcon = Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF0D2818)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
        );
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 14,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              // Animated 3D Icon at Top of Form
              role3DIcon,

              const SizedBox(height: 12),

              // Title & Hindi Title
              Text(
                roleName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: roleColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$hindiRole में साइन इन करें',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Mobile / Email Input
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Registered Mobile Number or Email',
                  hintText: 'e.g. 9876543210 or user@bainada.com',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: roleColor, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAF9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: roleColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'कृपया मोबाइल नंबर या ईमेल दर्ज करें'
                    : null,
              ),

              const SizedBox(height: 14),

              // Password Input
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password / पासवर्ड',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: roleColor, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAF9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: roleColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'कृपया पासवर्ड दर्ज करें'
                    : null,
              ),

              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: roleColor.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'साइन इन करें (Sign In)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
