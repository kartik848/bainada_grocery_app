import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current Firebase Auth user
  User? get currentUser => _auth.currentUser;

  // Sign In with email & password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Authentication failed: ${e.toString()}');
    }
  }

  // Find user by phone in Firestore across multiple formats
  Future<UserModel?> findUserByPhone(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      if (clean.isEmpty) return null;

      final formats = [
        clean,
        '+91$clean',
        '91$clean',
        phone.trim(),
      ];

      for (final p in formats) {
        // 1. Check users collection
        final snap = await _firestore
            .collection('users')
            .where('phone', isEqualTo: p)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
        }

        // 2. Check merchants collection
        final mSnap = await _firestore
            .collection('merchants')
            .where('phone', isEqualTo: p)
            .limit(1)
            .get();
        if (mSnap.docs.isNotEmpty) {
          return UserModel.fromMap(mSnap.docs.first.data(), mSnap.docs.first.id);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign Up with email, password, and custom UserModel
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final createdUser = userModel.copyWith(uid: uid, email: email.trim());

      await _firestore.collection('users').doc(uid).set(createdUser.toMap());
      return createdUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Get user profile from Firestore with comprehensive fallback resolution
  Future<UserModel?> getUserData(String uid) async {
    try {
      // 1. Check direct doc in 'users'
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }

      // 2. Check direct doc in 'merchants'
      final merchantDoc =
          await _firestore.collection('merchants').doc(uid).get();
      if (merchantDoc.exists && merchantDoc.data() != null) {
        return UserModel.fromMap(merchantDoc.data()!, merchantDoc.id);
      }

      // 3. Search by Auth user email or phone across Firestore
      final authUser = _auth.currentUser;
      if (authUser != null && authUser.uid == uid) {
        final email = (authUser.email ?? '').trim();
        final phone = (authUser.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

        // Search 'users' by email
        if (email.isNotEmpty) {
          final q = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final found = UserModel.fromMap(q.docs.first.data(), q.docs.first.id);
            final updated = found.copyWith(uid: uid);
            await _firestore.collection('users').doc(uid).set(updated.toMap(), SetOptions(merge: true));
            return updated;
          }

          // Search 'merchants' by email
          final mq = await _firestore
              .collection('merchants')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (mq.docs.isNotEmpty) {
            final found = UserModel.fromMap(mq.docs.first.data(), mq.docs.first.id);
            final updated = found.copyWith(uid: uid);
            await _firestore.collection('users').doc(uid).set(updated.toMap(), SetOptions(merge: true));
            return updated;
          }
        }

        // Search by phone
        if (phone.isNotEmpty) {
          final foundByPhone = await findUserByPhone(phone);
          if (foundByPhone != null) {
            final updated = foundByPhone.copyWith(uid: uid);
            await _firestore.collection('users').doc(uid).set(updated.toMap(), SetOptions(merge: true));
            return updated;
          }
        }

        // 4. Baseline profile creation if no record found in Firestore
        final bool isMasterAdmin = email.toLowerCase() == 'ajay14@gmail.com' ||
            email.toLowerCase().contains('admin') ||
            email.toLowerCase() == 'bainadabrothers@gmail.com';

        final fallbackName = (email.toLowerCase() == 'ajay14@gmail.com')
            ? 'Ajay Meena'
            : (authUser.displayName?.isNotEmpty == true
                ? authUser.displayName!
                : (email.isNotEmpty ? email.split('@').first : 'Ajay Meena'));

        final fallbackUser = UserModel(
          uid: uid,
          name: fallbackName,
          phone: authUser.phoneNumber ?? '',
          email: email,
          role: isMasterAdmin ? UserRole.admin : UserRole.merchant,
          isApproved: true,
          isActive: true,
          createdAt: DateTime.now(),
        );
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .set(fallbackUser.toMap(), SetOptions(merge: true));
        } catch (_) {}
        return fallbackUser;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream user profile for real-time changes
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().asyncMap(
      (doc) async {
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }

        // Fallback check
        return await getUserData(uid);
      },
    );
  }

  // Update user profile
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  // Save / Upsert user profile
  Future<void> setUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: ${e.toString()}');
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Friendly error message converter
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No registered account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled by the admin.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
