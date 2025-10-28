import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _keyUser = 'user_data';
  static const String _keyToken = 'session_token';
  static const String _keyBaseUrl = 'base_url';

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
    ApiService.setSessionToken(null);
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
