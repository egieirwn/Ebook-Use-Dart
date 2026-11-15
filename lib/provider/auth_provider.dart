import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:ebook/model/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  User? get firebaseUser => _auth.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        _error = 'Data pengguna tidak ditemukan di database.';
        return false;
      }

      _user = UserModel.fromFirestore(doc);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    String dob = '',
    String address = '',
  }) async {
    _error = null;
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final newUser = UserModel(
        uid: uid,
        email: email.trim(),
        fullName: fullName,
        phone: phone,
        dob: dob,
        address: address,
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      _user = newUser;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCurrentUser() async {
    final current = _auth.currentUser;
    if (current == null) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(current.uid).get();
      _user = doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Pengguna tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan autentikasi: $code';
    }
  }
}
