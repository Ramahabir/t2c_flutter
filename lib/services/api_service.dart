import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/redemption_request.dart';

class ApiService {
  static String _baseUrl = 'http://192.168.1.50:8080'; // Default LAN address
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

  // QR Code Login - Authenticate via scanned QR token
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
