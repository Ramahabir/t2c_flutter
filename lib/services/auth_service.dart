import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _keyUser = 'user_data';
  static const String _keyToken = 'session_token';
  static const String _keyBaseUrl = 'base_url';
  static const String _keyAppUser = 'app_user_data'; // For app login

  final ApiService _apiService = ApiService();

  // Save user session to local storage
  Future<void> saveSession(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setString(_keyToken, token);
    ApiService.setSessionToken(token);
  }

  // Load user session from local storage
  Future<User?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_keyUser);
      final token = prefs.getString(_keyToken);

      if (userData != null && token != null) {
        ApiService.setSessionToken(token);
        return User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      print('Failed to load session: $e');
    }
    return null;
  }

  // Clear user session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyAppUser);
    ApiService.setSessionToken(null);
  }

  // Save app user session (for login/register)
  Future<void> saveAppUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppUser, jsonEncode(user.toJson()));
  }

  // Load app user session
  Future<User?> loadAppUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_keyAppUser);

      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      print('Failed to load app user session: $e');
    }
    return null;
  }

  // Register new user with backend
  Future<User> register(String name, String email, String password) async {
    try {
      final response = await _apiService.register(name, email, password);
      
      print('Auth service received response: $response');
      
      // Handle different response structures
      Map<String, dynamic> userData;
      String? token;
      
      // Check if response has nested 'data' object (backend format)
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        userData = data['user'] as Map<String, dynamic>;
        token = data['token'] as String?;
      }
      // Check if response has 'user' at root level
      else if (response.containsKey('user')) {
        userData = response['user'] as Map<String, dynamic>;
        token = response['sessionToken'] as String?;
      }
      // Check if user data is at root level (no nesting)
      else if (response.containsKey('id')) {
        userData = response;
        token = response['sessionToken'] as String?;
      }
      else {
        throw Exception('Invalid response structure: missing user data');
      }
      
      // Convert backend field names to User model fields
      final userJson = {
        'id': userData['id']?.toString() ?? '',
        'name': userData['full_name'] ?? userData['name'],
        'email': userData['email'],
        'points': (userData['total_points'] ?? userData['points'] ?? 0).toDouble(),
        'sessionToken': token,
      };
      
      final user = User.fromJson(userJson);
      
      // Save app user session
      await saveAppUserSession(user);
      
      // If session token is provided, save it
      if (token != null) {
        await saveSession(user, token);
      }
      
      return user;
    } catch (e) {
      print('Registration error in auth_service: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      
      print('Auth service received response: $response');
      
      // Handle different response structures
      Map<String, dynamic> userData;
      String? token;
      
      // Check if response has nested 'data' object (backend format)
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        userData = data['user'] as Map<String, dynamic>;
        token = data['token'] as String?;
      }
      // Check if response has 'user' at root level
      else if (response.containsKey('user')) {
        userData = response['user'] as Map<String, dynamic>;
        token = response['sessionToken'] as String?;
      }
      // Check if user data is at root level (no nesting)
      else if (response.containsKey('id')) {
        userData = response;
        token = response['sessionToken'] as String?;
      }
      else {
        throw Exception('Invalid response structure: missing user data');
      }
      
      // Convert backend field names to User model fields
      final userJson = {
        'id': userData['id']?.toString() ?? '',
        'name': userData['full_name'] ?? userData['name'],
        'email': userData['email'],
        'points': (userData['total_points'] ?? userData['points'] ?? 0).toDouble(),
        'sessionToken': token,
      };
      
      final user = User.fromJson(userJson);
      
      // Save app user session
      await saveAppUserSession(user);
      
      // If session token is provided, save it
      if (token != null) {
        await saveSession(user, token);
      }
      
      return user;
    } catch (e) {
      print('Login error in auth_service: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Generate QR code for login
  Future<Map<String, dynamic>> generateQrLogin() async {
    try {
      return await _apiService.generateQrLogin();
    } catch (e) {
      throw Exception('Failed to generate QR login: $e');
    }
  }

  // Verify QR token with credentials
  Future<User> verifyQrToken(String token, String email, String password) async {
    try {
      final response = await _apiService.verifyQrToken(token, email, password);
      final user = User.fromJson(response['user']);
      final sessionToken = response['sessionToken'];
      
      if (sessionToken != null) {
        await saveSession(user, sessionToken);
      }
      
      return user;
    } catch (e) {
      throw Exception('Token verification failed: $e');
    }
  }

  // Login with QR code
  Future<User> loginWithQrCode(String qrToken) async {
    try {
      final user = await _apiService.loginWithQrToken(qrToken);
      final token = ApiService.getSessionToken();
      if (token != null) {
        await saveSession(user, token);
      }
      return user;
    } catch (e) {
      throw Exception('QR login failed: $e');
    }
  }

  // Refresh user data
  Future<User> refreshUserData() async {
    try {
      final user = await _apiService.getUserProfile();
      final token = ApiService.getSessionToken();
      if (token != null) {
        await saveSession(user, token);
      }
      return user;
    } catch (e) {
      throw Exception('Failed to refresh user data: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    await clearSession();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await loadSession();
    return user != null;
  }

  // Save/Load base URL configuration
  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
    ApiService.setBaseUrl(url);
  }

  Future<String?> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyBaseUrl);
    if (url != null) {
      ApiService.setBaseUrl(url);
    }
    return url;
  }
}
