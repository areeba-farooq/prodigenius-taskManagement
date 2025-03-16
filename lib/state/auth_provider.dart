// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class User {
//   final String id;
//   final String name;
//   final String email;

//   User({required this.id, required this.name, required this.email});

//   Map<String, dynamic> toMap() {
//     return {'id': id, 'name': name, 'email': email};
//   }

//   // Create user object from a map
//   factory User.fromMap(Map<String, dynamic> map) {
//     return User(id: map['id'], name: map['name'], email: map['email']);
//   }

//   // Serialize to JSON
//   String toJson() => json.encode(toMap());

//   // Create user from JSON
//   factory User.fromJson(String source) => User.fromMap(json.decode(source));
// }

// class AuthProvider extends ChangeNotifier {
//   User? _currentUser;
//   bool _isLoading = false;
//   String? _error;
//   // Shared preferences key
//   static const String _userKey = 'user_data';
//   // Getters
//   User? get currentUser => _currentUser;
//   bool get isLoggedIn => _currentUser != null;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   // For development/testing - simulated user database
//   final List<Map<String, String>> _users = [
//     {
//       'id': '1',
//       'name': 'John Doe',
//       'email': 'john@example.com',
//       'password': 'password123',
//     },
//   ];
//   // Constructor - load user from shared preferences
//   AuthProvider() {
//     _loadUserFromPrefs();
//   }

//   // Load user data from shared preferences
//   Future<void> _loadUserFromPrefs() async {
//     _setLoading(true);
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userData = prefs.getString(_userKey);

//       if (userData != null) {
//         _currentUser = User.fromJson(userData);
//       }
//     } catch (e) {
//       print('Error loading user data: $e');
//     } finally {
//       _setLoading(false);
//     }
//     notifyListeners();
//   }

//   // Save user data to shared preferences
//   Future<void> _saveUserToPrefs(User user) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_userKey, user.toJson());
//     } catch (e) {
//       print('Error saving user data: $e');
//     }
//   }

//   // Clear user data from shared preferences
//   Future<void> _clearUserFromPrefs() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(_userKey);
//     } catch (e) {
//       print('Error clearing user data: $e');
//     }
//   }

//   // Clear error message
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   // Set loading state
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }

//   // Login with email and password
//   Future<bool> login(String email, String password) async {
//     clearError();
//     _setLoading(true);

//     // Simulate network delay
//     await Future.delayed(const Duration(seconds: 1));

//     try {
//       // Find user with matching email
//       final userIndex = _users.indexWhere((user) => user['email'] == email);

//       if (userIndex == -1) {
//         _error = 'User not registered. Please sign up first.';
//         _setLoading(false);
//         notifyListeners();
//         return false;
//       }

//       if (_users[userIndex]['password'] != password) {
//         _error = 'Incorrect password. Please try again.';
//         _setLoading(false);
//         notifyListeners();
//         return false;
//       }

//       // Login successful
//       _currentUser = User(
//         id: _users[userIndex]['id']!,
//         name: _users[userIndex]['name']!,
//         email: _users[userIndex]['email']!,
//       );
//       // Save user to shared preferences
//       await _saveUserToPrefs(_currentUser!);
//       _setLoading(false);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _error = 'Login failed. Please try again.';
//       _setLoading(false);
//       notifyListeners();
//       return false;
//     }
//   }

//   // Register a new user
//   Future<bool> register(String name, String email, String password) async {
//     clearError();
//     _setLoading(true);

//     // Simulate network delay
//     await Future.delayed(const Duration(seconds: 1));

//     try {
//       // Check if email already exists
//       final userExists = _users.any((user) => user['email'] == email);

//       if (userExists) {
//         _error = 'This email is already registered. Please login instead.';
//         _setLoading(false);
//         notifyListeners();
//         return false;
//       }

//       // Create new user
//       final String id = (_users.length + 1).toString();
//       _users.add({
//         'id': id,
//         'name': name,
//         'email': email,
//         'password': password,
//       });

//       // Auto login after registration
//       _currentUser = User(id: id, name: name, email: email);
//       // Save user to shared preferences
//       await _saveUserToPrefs(_currentUser!);
//       _setLoading(false);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _error = 'Registration failed. Please try again.';
//       _setLoading(false);
//       notifyListeners();
//       return false;
//     }
//   }

//   // Logout
//   Future<void> logout() async {
//     // Clear user data from shared preferences
//     await _clearUserFromPrefs();
//     _currentUser = null;
//     notifyListeners();
//   }
// }

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return {
      'id': id, 
      'name': name, 
      'email': email,
      'photoUrl': photoUrl,
    };
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
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Shared preferences key
  static const String _userKey = 'user_data';
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor - initialize Firebase Auth state listener
  AuthProvider() {
    _initAuthListener();
    _loadUserFromPrefs();
  }

  // Initialize Firebase Auth state listener
  void _initAuthListener() {
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // User is signed in
        await _getUserDataFromFirestore(firebaseUser);
      } else {
        // User is signed out
        _currentUser = null;
        await _clearUserFromPrefs();
        notifyListeners();
      }
    });
  }

  // Get user data from Firestore
  Future<void> _getUserDataFromFirestore(firebase_auth.User firebaseUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        // User exists in Firestore
        final userData = userDoc.data() as Map<String, dynamic>;
        _currentUser = User.fromMap({
          'id': firebaseUser.uid,
          'name': userData['name'] ?? firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
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
      notifyListeners();
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      // Fallback to Firebase Auth data
      _currentUser = User.fromFirebaseUser(firebaseUser);
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    clearError();
    _setLoading(true);

    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update last login timestamp
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        _setLoading(false);
        return true;
      }
      
      _error = 'Login failed. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      if (e.code == 'user-not-found') {
        _error = 'No user found with this email. Please sign up first.';
      } else if (e.code == 'wrong-password') {
        _error = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        _error = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        _error = 'This account has been disabled.';
      } else {
        _error = 'Login error: ${e.message}';
      }
      
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register(String name, String email, String password) async {
    clearError();
    _setLoading(true);

    try {
      // Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);
        
        // Create user object
        _currentUser = User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
        );
        
        // Save user to Firestore
        await _saveUserToFirestore(_currentUser!);
        
        // Save to shared prefs
        await _saveUserToPrefs(_currentUser!);
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _error = 'Registration failed. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      if (e.code == 'weak-password') {
        _error = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _error = 'This email is already registered. Please login instead.';
      } else if (e.code == 'invalid-email') {
        _error = 'Invalid email address.';
      } else {
        _error = 'Registration error: ${e.message}';
      }
      
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _setLoading(false);
      notifyListeners();
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
      await _firestore.collection('users').doc(_currentUser!.id).update(updatedData);
      
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
  Future<bool> changePassword(String currentPassword, String newPassword) async {
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
      await _firebaseAuth.signOut();
      _currentUser = null;
      await _clearUserFromPrefs();
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}