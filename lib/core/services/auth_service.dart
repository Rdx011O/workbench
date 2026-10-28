import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../database/database_service.dart';

class AuthUser {
  final String id;
  final String email;
  final String username;
  final String? googleEmail;
  final bool isGoogleLinked;
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.username,
    this.googleEmail,
    this.isGoogleLinked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'username': username,
        'google_email': googleEmail,
        'is_google_linked': isGoogleLinked ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
        id: map['id'] as String,
        email: map['email'] as String,
        username: map['username'] as String,
        googleEmail: map['google_email'] as String?,
        isGoogleLinked: (map['is_google_linked'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  String _hashPassword(String password) {
    int hash = 5381;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) + hash) + password.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toString();
  }

  Future<void> initialize(DatabaseService db) async {
    await db.ensureUserAuthTable();

    // Check Firebase Auth current user first
    try {
      final fbUser = _auth?.currentUser;
      if (fbUser != null && _firestore != null) {
        final doc = await _firestore!.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _currentUser = AuthUser(
            id: fbUser.uid,
            email: fbUser.email ?? (data['email'] as String? ?? ''),
            username: data['username'] as String? ?? (fbUser.displayName ?? 'User'),
            googleEmail: data['google_email'] as String?,
            isGoogleLinked: data['is_google_linked'] == true,
            createdAt: data['created_at'] != null
                ? DateTime.parse(data['created_at'] as String)
                : DateTime.now(),
          );
          await db.setLoggedInUser(_currentUser!.id);
          debugPrint('[AuthService] Firebase session restored: ${_currentUser?.email}');
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase session check fallback: $e');
    }

    // Fallback to local session
    _currentUser = await db.getLoggedInUser();
    debugPrint('[AuthService] Local session check – isLoggedIn=$isLoggedIn user=${_currentUser?.email}');
  }

  /// Sign up with email + password using Firebase Auth + Cloud Firestore
  Future<AuthUser?> signUp({
    required DatabaseService db,
    required String email,
    required String password,
    required String username,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim();

    try {
      if (_auth != null) {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final uid = credential.user?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
        await credential.user?.updateDisplayName(cleanUsername);

        final user = AuthUser(
          id: uid,
          email: cleanEmail,
          username: cleanUsername,
          createdAt: DateTime.now(),
        );

        // Save to Cloud Firestore in cloud collection
        try {
          await _firestore?.collection('users').doc(uid).set({
            'id': uid,
            'email': cleanEmail,
            'username': cleanUsername,
            'is_google_linked': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('[AuthService] Firestore profile save: $e');
        }

        // Cache locally for offline availability
        await db.insertAuthUser(user, _hashPassword(password));
        await db.setLoggedInUser(user.id);
        _currentUser = user;
        return user;
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase signUp error: $e');
      // If Firebase email is already in use, return null
      if (e.toString().contains('email-already-in-use')) {
        return null;
      }
    }

    // Fallback to local SQLite if Firebase is unavailable/offline
    final existing = await db.getUserByEmail(cleanEmail);
    if (existing != null) return null;

    final localUser = AuthUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: cleanEmail,
      username: cleanUsername,
      createdAt: DateTime.now(),
    );
    await db.insertAuthUser(localUser, _hashPassword(password));
    await db.setLoggedInUser(localUser.id);
    _currentUser = localUser;
    return localUser;
  }

  /// Sign in with email + password using Firebase Auth + Cloud Firestore
  Future<AuthUser?> signIn({
    required DatabaseService db,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      if (_auth != null) {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final uid = credential.user?.uid ?? '';
        String resolvedUsername = credential.user?.displayName ?? cleanEmail.split('@').first;

        // Fetch cloud profile from Firestore
        try {
          final doc = await _firestore?.collection('users').doc(uid).get();
          if (doc != null && doc.exists && doc.data() != null) {
            resolvedUsername = doc.data()!['username'] as String? ?? resolvedUsername;
          }
        } catch (_) {}

        final user = AuthUser(
          id: uid,
          email: cleanEmail,
          username: resolvedUsername,
          createdAt: DateTime.now(),
        );

        await db.insertAuthUser(user, _hashPassword(password));
        await db.setLoggedInUser(user.id);
        _currentUser = user;
        return user;
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase signIn error: $e');
    }

    // Fallback to local authentication
    final user = await db.getUserByEmailAndPassword(
      cleanEmail,
      _hashPassword(password),
    );
    if (user != null) {
      await db.setLoggedInUser(user.id);
      _currentUser = user;
    }
    return user;
  }

  /// Google sign-in: syncs account credentials directly to Firebase & Cloud Firestore
  Future<AuthUser?> signInWithGoogle({
    required DatabaseService db,
    required String googleEmail,
    required String username,
  }) async {
    final cleanEmail = googleEmail.trim().toLowerCase();
    final cleanUsername = username.trim();

    final uid = 'google_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    // Save cloud profile to Firestore
    try {
      await _firestore?.collection('users').doc(uid).set({
        'id': uid,
        'email': cleanEmail,
        'username': cleanUsername,
        'google_email': cleanEmail,
        'is_google_linked': true,
        'created_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthService] Firestore google sync: $e');
    }

    final user = AuthUser(
      id: uid,
      email: cleanEmail,
      username: cleanUsername,
      googleEmail: cleanEmail,
      isGoogleLinked: true,
      createdAt: DateTime.now(),
    );

    await db.insertAuthUser(user, '');
    await db.setLoggedInUser(user.id);
    _currentUser = user;
    return user;
  }

  Future<void> signOut(DatabaseService db) async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    await db.clearLoggedInUser();
    _currentUser = null;
  }

  Future<void> updateUsername(DatabaseService db, String newUsername) async {
    if (_currentUser == null) return;
    final cleanName = newUsername.trim();

    try {
      await _auth?.currentUser?.updateDisplayName(cleanName);
      await _firestore?.collection('users').doc(_currentUser!.id).update({
        'username': cleanName,
      });
    } catch (e) {
      debugPrint('[AuthService] Firestore username update: $e');
    }

    final updated = AuthUser(
      id: _currentUser!.id,
      email: _currentUser!.email,
      username: cleanName,
      googleEmail: _currentUser!.googleEmail,
      isGoogleLinked: _currentUser!.isGoogleLinked,
      createdAt: _currentUser!.createdAt,
    );
    await db.updateAuthUser(updated);
    _currentUser = updated;
  }
}
