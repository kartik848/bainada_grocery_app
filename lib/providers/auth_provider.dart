import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/live_mode_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final LiveModeService _liveModeService = LiveModeService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userDocSubscription;
  StreamSubscription<bool>? _liveModeSubscription;

  User? _firebaseUser;
  UserModel? _currentUserModel;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLiveMode = false;
  bool _isLiveModeAvailable = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLiveMode => _isLiveMode;
  bool get isLiveModeAvailable => _isLiveModeAvailable;

  bool get isAuthenticated => _currentUserModel != null;
  UserRole? get userRole => _currentUserModel?.role;

  bool get isAdmin => _currentUserModel?.role == UserRole.admin;
  bool get isSalesman => _currentUserModel?.role == UserRole.salesman;
  bool get isMerchant => _currentUserModel?.role == UserRole.merchant;
  bool get isDeliveryBoy => _currentUserModel?.role == UserRole.deliveryBoy;

  AuthProvider() {
    _initAuthListener();
    _initLiveModeListener();
  }

  void _initLiveModeListener() {
    _liveModeSubscription = _liveModeService.liveModeStream.listen(
      (enabled) {
        _isLiveMode = enabled;
        _isLiveModeAvailable = true;
        notifyListeners();
      },
      onError: (_) {
        _isLiveMode = false;
        _isLiveModeAvailable = false;
        notifyListeners();
      },
    );
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _subscribeToUserData(user.uid);
      } else {
        _userDocSubscription?.cancel();
        _currentUserModel = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _subscribeToUserData(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _authService.streamUserData(uid).listen(
      (UserModel? userModel) {
        if (userModel != null) {
          _currentUserModel = userModel;
        } else {
          _currentUserModel = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String input = emailOrPhone.trim();
      List<String> emailsToTry = [];

      if (input.contains('@')) {
        emailsToTry.add(input);
      } else {
        final cleanPhone = input.replaceAll(RegExp(r'\D'), '');
        final foundUser = await _authService.findUserByPhone(cleanPhone);
        if (foundUser != null && foundUser.email.isNotEmpty) {
          emailsToTry.add(foundUser.email);
        }
        emailsToTry.add('$cleanPhone@bainada.com');
        emailsToTry.add('$cleanPhone@kirana.bainada.com');
        emailsToTry.add('$cleanPhone@grocery.bainada.com');
      }

      dynamic lastError;
      for (final email in emailsToTry) {
        try {
          final credential = await _authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final uid = credential.user!.uid;
          final userDoc = await _authService.getUserData(uid);
          if (userDoc != null) {
            _currentUserModel = userDoc;
          }
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          lastError = e;
        }
      }

      _errorMessage = lastError?.toString().replaceAll('Exception:', '').trim() ??
          'Invalid login credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdUser = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        userModel: userModel,
      );
      _currentUserModel = createdUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUserData(updatedUser);
      _currentUserModel = updatedUser;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (_) {}
    _currentUserModel = null;
    _firebaseUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    _liveModeSubscription?.cancel();
    super.dispose();
  }
}
