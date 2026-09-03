import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';

class AddMerchantScreen extends StatefulWidget {
  final VoidCallback? onMerchantCreated;

  const AddMerchantScreen({super.key, this.onMerchantCreated});

  @override
  State<AddMerchantScreen> createState() => _AddMerchantScreenState();
}

class _AddMerchantScreenState extends State<AddMerchantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController(text: '50000');
  final _minOrderCtrl = TextEditingController(text: '1000');

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  // GPS Location state
  double? _latitude;
  double? _longitude;
  String? _detectedAddress;
  bool _isFetchingLocation = false;

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final loc = await LocationService().getLiveLocationDetails();
      if (loc != null) {
        setState(() {
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _detectedAddress = loc.address;
          if (_addressCtrl.text.trim().isEmpty && loc.address != null) {
            _addressCtrl.text = loc.address!;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('दुकान की लोकेशन मैप से सफलतापूर्वक टैग हो गई! (GPS Tagged)'),
              backgroundColor: Color(0xFF1B5E20),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लोकेशन नहीं मिल सकी। कृपया फोन का GPS / Location On करें।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _gstinCtrl.dispose();
    _creditLimitCtrl.dispose();
    _minOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _shareOnWhatsApp({
    required String phone,
    required String shopName,
    required String ownerName,
    required String loginId,
    required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final String message = '''
🏪 *Welcome to Bainada Brothers Wholesale!*
प्रिय ${ownerName.isNotEmpty ? ownerName : "व्यापारी"}, आपकी दुकान *$shopName* का थोक खाता सफलतापूर्वक खुल गया है।

🔑 *आपकी लॉगिन जानकारी (Login Credentials):*
📱 *Login ID / User:* $loginId
🔒 *Password:* $password

📲 Bainada Grocery Wholesale App से कभी भी सीधे थोक भाव पर आटा, तेल, दाल, चीनी का आर्डर बुक करें।
धन्यवाद!
_Bainada Brothers Wholesale, Jaipur_
''';

    final Uri whatsappUri = Uri.parse('https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Credentials displayed on screen.')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match! Please check again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentSalesman = auth.currentUserModel;

    final shopName = _storeNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final customEmail = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final landmark = _landmarkCtrl.text.trim();
    final gstin = _gstinCtrl.text.trim();
    final creditLimit = double.tryParse(_creditLimitCtrl.text.trim()) ?? 50000.0;
    final minOrder = double.tryParse(_minOrderCtrl.text.trim()) ?? 1000.0;

    // Login ID / Email identifier
    final loginEmail = customEmail.isNotEmpty
        ? customEmail.toLowerCase()
        : '$phone@kirana.bainada.com';

    String createdUid = 'merchant_${DateTime.now().millisecondsSinceEpoch}';

    // Create Firebase Auth user safely using secondary FirebaseApp instance
    FirebaseApp? secondaryApp;
    try {
      final appName = 'MerchantAuth_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      if (userCred.user != null) {
        createdUid = userCred.user!.uid;
      }
    } catch (authError) {
      debugPrint('Secondary Firebase Auth note: $authError');
      // If auth creation fails (e.g. already in use or offline), fallback to unique UID
    } finally {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }

    final newMerchant = UserModel(
      uid: createdUid,
      name: ownerName,
      shopName: shopName,
      phone: phone,
      email: loginEmail,
      role: UserRole.merchant,
      address: address.isNotEmpty ? address : 'Jaipur Mandi Area, Rajasthan',
      landmark: landmark.isNotEmpty ? landmark : null,
      gstin: gstin.isNotEmpty ? gstin : null,
      creditLimit: creditLimit,
      outstandingDue: 0.0,
      minOrderLimit: minOrder,
      addedBySalesmanId: currentSalesman?.uid,
      addedBySalesmanName: currentSalesman?.name,
      latitude: _latitude,
      longitude: _longitude,
      locationAddress: _detectedAddress,
      isApproved: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      // 1. Save to 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUid)
          .set(newMerchant.toMap(), SetOptions(merge: true));

      // 2. Also save to 'merchants' collection
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(createdUid)
          .set(newMerchant.toMap(), SetOptions(merge: true));

      // Select newly created merchant in CartProvider for instant order booking
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).setSelectedMerchant(newMerchant);
      }

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      // Show Success Dialog with 1-Tap WhatsApp Share
      _showSuccessDialog(
        merchant: newMerchant,
        loginId: loginEmail,
        password: password,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to onboard merchant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog({
    required UserModel merchant,
    required String loginId,
    required String password,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Merchant Onboarded!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kirana store "${merchant.shopName}" is now active and attributed to you.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Credentials Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFAED581)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔑 Instant Merchant Login Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF33691E)),
                    ),
                    const Divider(color: Color(0xFFAED581), height: 16),
                    Row(
                      children: [
                        const Text('Login ID / User: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: SelectableText(
                            loginId,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Password: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: SelectableText(
                            password,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Credit Limit: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormatter.format(merchant.creditLimit),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1-Tap WhatsApp Share Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _shareOnWhatsApp(
                      phone: merchant.phone,
                      shopName: merchant.shopName ?? merchant.name,
                      ownerName: merchant.name,
                      loginId: loginId,
                      password: password,
                    );
                  },
                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                  label: const Text(
                    'Share Credentials on WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // Official WhatsApp Green
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Close screen / bottom sheet
              }
              widget.onMerchantCreated?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start Booking Order', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboard New Kirana Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront, color: Color(0xFFE65100), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kirana Store Onboarding Form',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                          ),
                          Text(
                            'Instantly generate merchant login credentials & assign initial credit limit.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF8D6E63)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Shop & Contact Info
              _buildSectionTitle('1. Store & Owner Information'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _storeNameCtrl,
                decoration: _inputDec(
                  label: 'Store / Business Name *',
                  hint: 'e.g. Mahadev Kirana & General Store',
                  icon: Icons.store_mall_directory_outlined,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter shop name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ownerNameCtrl,
                decoration: _inputDec(
                  label: 'Owner / Contact Person Name *',
                  hint: 'e.g. Ramesh Kumar Sharma',
                  icon: Icons.person_outline,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter owner name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDec(
                  label: 'WhatsApp Phone Number *',
                  hint: 'e.g. 9829012345 (10 digits)',
                  icon: Icons.phone_outlined,
                  prefixText: '+91 ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter WhatsApp phone number';
                  final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.length < 10) return 'Enter valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 📍 GPS Shop Location Tagging (Blinkit Style)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _latitude != null
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _latitude != null
                        ? const Color(0xFF86EFAC)
                        : AppColors.border,
                    width: _latitude != null ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _latitude != null
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                          size: 20,
                          color: _latitude != null
                              ? const Color(0xFF16A34A)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _latitude != null
                                ? 'दुकान की लोकेशन मैप से लिंक हो गई (GPS Tagged)'
                                : 'Shop GPS Location / दुकान की लोकेशन मैप से लें',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _latitude != null
                                  ? const Color(0xFF15803D)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'GPS Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534)),
                      ),
                      if (_detectedAddress != null &&
                          _detectedAddress!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _detectedAddress!,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF166534)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isFetchingLocation
                                ? null
                                : _fetchCurrentLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(
                                    _latitude != null
                                        ? Icons.refresh_rounded
                                        : Icons.near_me_rounded,
                                    size: 16),
                            label: Text(
                              _latitude != null
                                  ? 'अपडेट करें (Re-tag GPS)'
                                  : 'वर्तमान लोकेशन लें (GPS Auto-Detect)',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _latitude != null
                                  ? const Color(0xFF16A34A)
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              LocationService.openGoogleMapsNavigation(
                                destinationLat: _latitude!,
                                destinationLng: _longitude!,
                              );
                            },
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('मैप देखें',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDec(
                  label: 'Full Address / Mandi Area *',
                  hint: 'e.g. Shop 14, Surajpole Mandi, Jaipur',
                  icon: Icons.location_on_outlined,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter store address' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _landmarkCtrl,
                decoration: _inputDec(
                  label: 'Landmark (Optional)',
                  hint: 'e.g. Near Water Tank, Opp. SBI Bank',
                  icon: Icons.map_outlined,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _gstinCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDec(
                  label: 'GSTIN (Optional)',
                  hint: 'e.g. 08AAAAA1234A1Z5',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Login Credentials
              _buildSectionTitle('2. Mandatory Login Credentials'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDec(
                  label: 'Login Email / Identifier (Optional)',
                  hint: 'Defaults to [phone]@kirana.bainada.com',
                  icon: Icons.alternate_email_outlined,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: _inputDec(
                  label: 'Login Password *',
                  hint: 'Minimum 6 characters',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter password';
                  if (v.trim().length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDec(
                  label: 'Confirm Password *',
                  hint: 'Re-enter same password',
                  icon: Icons.lock_clock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Confirm password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Section 3: Credit Limit & Limits
              _buildSectionTitle('3. Khata Credit & Limits'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _creditLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec(
                        label: 'Credit Limit (₹)*',
                        hint: '50000',
                        icon: Icons.currency_rupee,
                        prefixText: '₹ ',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter credit limit' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec(
                        label: 'Min Order Limit (₹)',
                        hint: '1000',
                        icon: Icons.shopping_basket_outlined,
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_reg_rounded),
                  label: Text(
                    _isSubmitting ? 'Onboarding Kirana...' : 'Complete Onboarding & Create Login',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFFE65100),
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDec({
    required String label,
    String? hint,
    required IconData icon,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFFE65100)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.8)),
    );
  }
}
