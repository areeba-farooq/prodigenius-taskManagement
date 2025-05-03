import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/state/task_provider.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'photoUrl': photoUrl};
  }

  // Create user object from a map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  // Serialize to JSON
  String toJson() => json.encode(toMap());

  // Create user from JSON
  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  // Create user from Firebase user
  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      name:
          firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'User',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  BuildContext? _context;

  // Shared preferences key
  static const String _userKey = 'user_data';

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // Store context for accessing providers
  void setContext(BuildContext context) {
    _context = context;
  }

  // Constructor - initialize Firebase Auth state listener
  AuthProvider() {
    _initAuthListener();
    _loadUserFromPrefs();
  }

  // Initialize Firebase Auth state listener
  void _initAuthListener() {
    _firebaseAuth.authStateChanges().listen((
      firebase_auth.User? firebaseUser,
    ) async {
      if (firebaseUser != null) {
        // User is signed in
        await _getUserDataFromFirestore(firebaseUser);
      } else {
        // User is signed out
        _currentUser = null;
        await _clearUserFromPrefs();
        //Clear TaskProvider data when user signs out
        if (_context != null) {
          Provider.of<TaskProvider>(_context!, listen: false).clearUser();
        }

        notifyListeners();
      }
    });
  }

  // Get user data from Firestore
  Future<void> _getUserDataFromFirestore(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        // User exists in Firestore
        final userData = userDoc.data() as Map<String, dynamic>;
        _currentUser = User.fromMap({
          'id': firebaseUser.uid,
          'name':
              userData['name'] ??
              firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          'email': userData['email'] ?? firebaseUser.email ?? '',
          'photoUrl': userData['photoUrl'] ?? firebaseUser.photoURL,
        });
      } else {
        // User not yet in Firestore, create from Firebase Auth data
        _currentUser = User.fromFirebaseUser(firebaseUser);

        // Save user data to Firestore
        await _saveUserToFirestore(_currentUser!);
      }

      // Save to shared prefs for offline access
      await _saveUserToPrefs(_currentUser!);
      // Set up TaskProvider for this user
      if (_context != null && _currentUser != null) {
        await Provider.of<TaskProvider>(
          _context!,
          listen: false,
        ).setUser(_currentUser!.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      // Fallback to Firebase Auth data
      _currentUser = User.fromFirebaseUser(firebaseUser);
      await _saveUserToPrefs(_currentUser!);
      // Set up TaskProvider for this user even in error case
      if (_context != null && _currentUser != null) {
        await Provider.of<TaskProvider>(
          _context!,
          listen: false,
        ).setUser(_currentUser!.id);
      }
      notifyListeners();
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      print('Attempting to save user to Firestore: ${user.id}');

      final userDoc = _firestore.collection('users').doc(user.id);

      await userDoc.set({
        'uid': user.id, // Add this field
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'accountType': 'standard',
      }, SetOptions(merge: true));

      print('Successfully saved user to Firestore');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
    }
  }

  // Load user data from shared preferences
  Future<void> _loadUserFromPrefs() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null && _currentUser == null) {
        _currentUser = User.fromJson(userData);
        // Set up TaskProvider for this user
        if (_context != null && _currentUser != null) {
          await Provider.of<TaskProvider>(
            _context!,
            listen: false,
          ).setUser(_currentUser!.id);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save user data to shared preferences
  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson());
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Clear user data from shared preferences
  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _autoClearErrorAfterDelay([int milliseconds = 5000]) async {
    if (_error != null) {
      await Future.delayed(Duration(milliseconds: milliseconds));
      clearError();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _getReadableErrorMessage(String code, String? serverMessage) {
    switch (code) {
      // Authentication errors
      case 'user-not-found':
        return 'No account exists with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please check and try again.';
      case 'invalid-email':
        return 'Invalid email format. Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later or reset your password.';
      case 'operation-not-allowed':
        return 'This type of login is temporarily disabled. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or try logging in.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';
      // Firestore errors (less common during auth but good to handle)
      case 'permission-denied':
        return 'Permission denied. Please try again or contact support if this persists.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      default:
        // Log the original error for debugging but don't show to user
        print('Unhandled error code: $code - $serverMessage');
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Improved login method with better error handling
  Future<bool> login(String email, String password) async {
    clearError();
    _setLoading(true);

    try {
      // Check if email is provided
      if (email.isEmpty) {
        _error = 'Please enter your email address.';
        _setLoading(false);
        notifyListeners();
        _autoClearErrorAfterDelay();
        return false;
      }

      // Check if password is provided
      if (password.isEmpty) {
        _error = 'Please enter your password.';
        _setLoading(false);
        notifyListeners();
        _autoClearErrorAfterDelay();
        return false;
      }

      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        try {
          // Try to update last login timestamp
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'lastLogin': FieldValue.serverTimestamp()});
        } catch (firestoreError) {
          // Just log the error but don't show to user
          print(
            'Warning: Could not update lastLogin timestamp: $firestoreError',
          );
        }

        _setLoading(false);
        return true;
      }

      _error = 'Login failed. Please try again.';
      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Use the helper method to get consistent user-friendly messages
      _error = _getReadableErrorMessage(e.code, e.message);

      // Log original error for debugging
      print('Firebase Auth error during login: ${e.code} - ${e.message}');

      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    } catch (e) {
      // Handle general exceptions
      print('Unexpected login error: ${e.toString()}');

      if (e.toString().contains('network')) {
        _error =
            'Network connection issue. Please check your internet and try again.';
      } else {
        _error = 'Unable to log in at this time. Please try again later.';
      }

      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    }
  }

  // Improved register method with better error handling
  Future<bool> register(String name, String email, String password) async {
    clearError();
    _setLoading(true);

    try {
      // Validate inputs before even attempting Firebase operations
      if (name.isEmpty) {
        _error = 'Please enter your full name.';
        _setLoading(false);
        notifyListeners();
        _autoClearErrorAfterDelay();
        return false;
      }

      if (email.isEmpty) {
        _error = 'Please enter your email address.';
        _setLoading(false);
        notifyListeners();
        _autoClearErrorAfterDelay();
        return false;
      }

      if (password.isEmpty) {
        _error = 'Please enter a password.';
        _setLoading(false);
        notifyListeners();
        _autoClearErrorAfterDelay();
        return false;
      }

      // Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Try to save user to Firestore
        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': name,
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
                'isActive': true,
                'accountType': 'standard',
              });
          print('User data saved to Firestore successfully');
        } catch (firestoreError) {
          print(
            'Warning: Could not save user data to Firestore: $firestoreError',
          );
        }

        // Sign out immediately so user needs to log in
        await _firebaseAuth.signOut();

        _setLoading(false);
        notifyListeners();
        return true;
      }

      _error = 'Registration failed. Please try again.';
      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Use the helper method to get consistent user-friendly messages
      _error = _getReadableErrorMessage(e.code, e.message);

      // Log original error for debugging
      print(
        'Firebase Auth error during registration: ${e.code} - ${e.message}',
      );

      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    } catch (e) {
      // Handle general exceptions
      print('Unexpected registration error: ${e.toString()}');

      if (e.toString().contains('network')) {
        _error =
            'Network connection issue. Please check your internet and try again.';
      } else {
        _error =
            'Unable to create account at this time. Please try again later.';
      }

      _setLoading(false);
      notifyListeners();
      _autoClearErrorAfterDelay();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    if (_currentUser == null) return false;

    clearError();
    _setLoading(true);

    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        _error = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Update display name in Firebase Auth if provided
      if (name != null && name.isNotEmpty) {
        await firebaseUser.updateDisplayName(name);
      }

      // Create updated user data
      final updatedData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (name != null && name.isNotEmpty) {
        updatedData['name'] = name;
      }

      if (photoUrl != null) {
        updatedData['photoUrl'] = photoUrl;
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updatedData);

      // Update local user object
      _currentUser = User(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );

      // Save to shared prefs
      await _saveUserToPrefs(_currentUser!);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return false;

    clearError();
    _setLoading(true);

    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null || firebaseUser.email == null) {
        _error = 'User not authenticated';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // Update password
      await firebaseUser.updatePassword(newPassword);

      _setLoading(false);
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _error = 'Current password is incorrect.';
      } else if (e.code == 'weak-password') {
        _error = 'New password is too weak.';
      } else {
        _error = 'Failed to change password: ${e.message}';
      }

      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to change password: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    clearError();
    _setLoading(true);

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _error = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        _error = 'Invalid email address.';
      } else {
        _error = 'Failed to send password reset email: ${e.message}';
      }

      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send password reset email: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear TaskProvider data before logging out
      if (_context != null) {
        Provider.of<TaskProvider>(_context!, listen: false).clearUser();
      }
      await _firebaseAuth.signOut();
      _currentUser = null;
      await _clearUserFromPrefs();
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
