import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  final _authController = StreamController<UserModel?>.broadcast();

  // Get current user
  UserModel? get currentUser => _currentUser;

  // Auth state changes stream
  Stream<UserModel?> get authStateChanges => _authController.stream;

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = UserModel.fromMap(json.decode(userData));
      _authController.add(_currentUser);
    } else {
      _authController.add(null);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(
      String email, String password) async {
    try {
      final response = await _apiService.post('users/login.php', {
        'email': email,
        'password': password,
      });

      _currentUser = UserModel.fromMap(response);
      
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(_currentUser!.toMap()));
      
      _authController.add(_currentUser);

      return _currentUser;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _apiService.post('users/register.php', {
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      // The register API returns the created user data
      _currentUser = UserModel(
        uid: response['uid'],
        email: response['email'],
        displayName: response['displayName'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Save to local storage (optional, or require login after register)
      // For now, let's auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(_currentUser!.toMap()));
      
      _authController.add(_currentUser);

      return _currentUser;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      _authController.add(null);
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get user data (refresh from server)
  Future<UserModel?> getUserData(String uid) async {
    // In a real app, we might have a specific endpoint to get user by ID
    // For now, if it's the current user, return it.
    if (_currentUser != null && _currentUser!.uid == uid) {
      return _currentUser;
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    // TODO: Implement update profile API
    // For now, just update local state
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(_currentUser!.toMap()));
  }

  // Follow/Unfollow user
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    // TODO: Implement follow API
  }

  // Check if following
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    // TODO: Implement check follow API
    return false;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // TODO: Implement reset password API
  }

  // Update seller rating
  Future<void> updateSellerRating(
      String userId, double average, int count) async {
    // TODO: Implement rating API
  }
}
