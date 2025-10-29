import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/redemption_request.dart';

class ApiService {
  static String _baseUrl = 'http://10.77.61.115:8080'; // Default LAN address
  static String? _sessionToken;
  WebSocketChannel? _wsChannel;

  // Configuration methods
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static void setSessionToken(String? token) {
    _sessionToken = token;
  }

  static String? getSessionToken() {
    return _sessionToken;
  }

  // Helper method to build headers
  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_sessionToken != null) {
      headers['Authorization'] = 'Bearer $_sessionToken';
    }
    return headers;
  }

  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['sessionToken'] != null) {
          _sessionToken = data['sessionToken'];
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Traditional login with email and password
  // Note: This uses the register endpoint approach or you may need to add a /api/auth/login endpoint on backend
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // If your backend has a /api/auth/login endpoint, update this URL
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response body is empty or null
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }
        
        final data = jsonDecode(response.body);
        
        // Check if data is null or not a Map
        if (data == null) {
          throw Exception('Null response from server');
        }
        
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid response format from server');
        }
        
        // Extract token from nested data structure if present
        if (data.containsKey('data') && data['data'] != null) {
          final nestedData = data['data'] as Map<String, dynamic>;
          if (nestedData['token'] != null) {
            _sessionToken = nestedData['token'];
          }
        } else if (data['sessionToken'] != null) {
          _sessionToken = data['sessionToken'];
        } else if (data['token'] != null) {
          _sessionToken = data['token'];
        }
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Generate QR code for login
  Future<Map<String, dynamic>> generateQrLogin() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/qr-login'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Returns { token, qrCode, expiresAt }
      } else {
        throw Exception('Failed to generate QR code');
      }
    } catch (e) {
      throw Exception('Failed to generate QR login: $e');
    }
  }

  // Verify QR token with credentials
  Future<Map<String, dynamic>> verifyQrToken(String token, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sessionToken'] != null) {
          _sessionToken = data['sessionToken'];
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Token verification failed');
      }
    } catch (e) {
      throw Exception('Failed to verify token: $e');
    }
  }

  // QR Code Login - Authenticate via scanned QR token (kept for backward compatibility)
  Future<User> loginWithQrToken(String qrToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/qr-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': qrToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionToken = data['sessionToken'];
        return User.fromJson(data['user']);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to login with QR code: $e');
    }
  }

  // Get User Profile
  Future<User> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Get Transaction History
  Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions?limit=$limit&offset=$offset'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['transactions'] ?? [];
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get transactions');
      }
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Get User Statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/stats'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  // Redeem Points
  Future<Map<String, dynamic>> redeemPoints(RedemptionRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/redemption/redeem'),
        headers: _buildHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Redemption failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to redeem points: $e');
    }
  }

  // Get Redemption Options
  Future<List<RedemptionOption>> getRedemptionOptions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/redemption/options'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> optionsJson = data['options'] ?? [];
        return optionsJson.map((json) => RedemptionOption.fromJson(json)).toList();
      } else {
        // Return default options if API doesn't support this yet
        return _getDefaultRedemptionOptions();
      }
    } catch (e) {
      // Fallback to default options
      return _getDefaultRedemptionOptions();
    }
  }

  List<RedemptionOption> _getDefaultRedemptionOptions() {
    return [
      RedemptionOption(
        id: 'cash',
        name: 'Cash Redemption',
        description: 'Convert points to cash at the station',
        minimumPoints: 100,
        icon: '💵',
      ),
      RedemptionOption(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        description: 'Direct transfer to your bank account',
        minimumPoints: 500,
        icon: '🏦',
      ),
      RedemptionOption(
        id: 'voucher',
        name: 'Gift Voucher',
        description: 'Redeem for shopping vouchers',
        minimumPoints: 250,
        icon: '🎁',
      ),
    ];
  }

  // WebSocket connection for real-time updates
  void connectWebSocket(String userId, Function(dynamic) onMessage) {
    try {
      final wsUrl = _baseUrl.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws?userId=$userId&token=$_sessionToken'),
      );

      _wsChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          onMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  // Logout
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: _buildHeaders(),
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _sessionToken = null;
      disconnectWebSocket();
    }
  }

  // Health check
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
