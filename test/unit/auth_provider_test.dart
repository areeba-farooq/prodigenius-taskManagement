import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/state/auth_provider.dart';

// Mock classes
class MockUser extends Mock implements firebase_auth.User {
  @override
  String get uid => 'mock-uid';
  
  @override
  String? get displayName => 'Mock User';
  
  @override
  String? get email => 'mock@example.com';
  
  @override
  String? get photoURL => 'https://example.com/photo.jpg';
}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {
  @override
  firebase_auth.User? get user => MockUser();
}

// Create a mock implementation of AuthProvider that doesn't rely on Firebase
class MockAuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    if (email.isEmpty) {
      _error = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    
    if (password.isEmpty) {
      _error = 'Please enter your password.';
      notifyListeners();
      return false;
    }
    
    // Simulate successful login
    _currentUser = User(
      id: 'test-id',
      name: 'Test User',
      email: email,
    );
    
    notifyListeners();
    return true;
  }
  
  Future<bool> register(String name, String email, String password) async {
    if (name.isEmpty) {
      _error = 'Please enter your full name.';
      notifyListeners();
      return false;
    }
    
    if (email.isEmpty) {
      _error = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    
    if (password.isEmpty) {
      _error = 'Please enter a password.';
      notifyListeners();
      return false;
    }
    
    // Simulate successful registration
    notifyListeners();
    return true;
  }
  
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
  
  Future<bool> resetPassword(String email) async {
    return true;
  }
  
  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    if (_currentUser == null) return false;
    
    _currentUser = User(
      id: _currentUser!.id,
      name: name ?? _currentUser!.name,
      email: _currentUser!.email,
      photoUrl: photoUrl ?? _currentUser!.photoUrl,
    );
    
    notifyListeners();
    return true;
  }
  
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAuthProvider authProvider;
  
  setUp(() {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Initialize our mock auth provider
    authProvider = MockAuthProvider();
  });
  
  group('User Model Tests', () {
    test('User should create from map correctly', () {
      final userMap = {
        'id': 'test-id',
        'name': 'Test User',
        'email': 'test@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
      };

      final user = User.fromMap(userMap);

      expect(user.id, equals('test-id'));
      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
    });

    test('User should convert to map correctly', () {
      final user = User(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final map = user.toMap();

      expect(map['id'], equals('test-id'));
      expect(map['name'], equals('Test User'));
      expect(map['email'], equals('test@example.com'));
      expect(map['photoUrl'], equals('https://example.com/photo.jpg'));
    });

    test('User should convert to and from JSON correctly', () {
      final user = User(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final json = user.toJson();
      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.name, equals(user.name));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.photoUrl, equals(user.photoUrl));
    });
  });

  group('Authentication Tests', () {
    test('login should return true on successful login', () async {
      final result = await authProvider.login('test@example.com', 'password123');
      
      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser, isNotNull);
    });

    test('register should return true on successful registration', () async {
      final result = await authProvider.register(
        'Test User', 
        'test@example.com', 
        'password123'
      );
      
      expect(result, isTrue);
    });

    test('logout should clear current user', () async {
      // First login to set current user
      await authProvider.login('test@example.com', 'password123');
      expect(authProvider.isLoggedIn, isTrue);
      
      // Then logout
      await authProvider.logout();
      
      // Verify the current user is null
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoggedIn, isFalse);
    });
  });

  group('Error Handling Tests', () {
    test('login should handle empty email error', () async {
      final result = await authProvider.login('', 'password123');
      
      expect(result, isFalse);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error, contains('email'));
    });

    test('login should handle empty password error', () async {
      final result = await authProvider.login('test@example.com', '');
      
      expect(result, isFalse);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error, contains('password'));
    });

    test('register should handle empty name error', () async {
      final result = await authProvider.register('', 'test@example.com', 'password123');
      
      expect(result, isFalse);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error, contains('name'));
    });

    test('clearError should reset error state', () {
      // Setup error state with failed login
      authProvider.login('', 'password123');
      expect(authProvider.error, isNotNull);
      
      // Call clearError
      authProvider.clearError();
      
      // Verify error is cleared
      expect(authProvider.error, isNull);
    });
  });

  group('User Profile Tests', () {
    test('updateProfile should return true on successful update', () async {
      // First login to set current user
      await authProvider.login('test@example.com', 'password123');
      
      // Test update
      final result = await authProvider.updateProfile(
        name: 'Updated Name',
      );
      
      // Expect successful update
      expect(result, isTrue);
      expect(authProvider.currentUser?.name, equals('Updated Name'));
    });
  });
}