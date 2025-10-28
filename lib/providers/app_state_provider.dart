import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/redemption_request.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  User? _user; // Station-linked user (from QR)
  User? _appUser; // App registered user (from login/register)
  List<Transaction> _transactions = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = false;
  String? _baseUrl;
  
  // Dummy user database (for MVP - replace with real backend)
  final Map<String, Map<String, String>> _dummyUsers = {
    'demo@trash2cash.com': {
      'name': 'Demo User',
      'email': 'demo@trash2cash.com',
      'password': 'demo123',
    },
  };

  // Getters
  User? get user => _user;
  User? get appUser => _appUser;
  List<Transaction> get transactions => _transactions;
  Map<String, dynamic>? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get baseUrl => _baseUrl;
  bool get isLoggedIn => _user != null;
  bool get isAppUserLoggedIn => _appUser != null;

  AppStateProvider() {
    _initializeApp();
  }

  // Initialize app - load saved session and base URL
  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load base URL
      _baseUrl = await _authService.loadBaseUrl();
      
      // Try to load saved app user session
      _appUser = await _authService.loadAppUserSession();
      
      // Try to load saved station session
      _user = await _authService.loadSession();
      
      if (_user != null) {
        // Refresh user data if logged in
        await refreshUserData();
        await loadTransactions();
        await loadUserStats();
      }
    } catch (e) {
      print('Initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with credentials (for app login)
  Future<void> loginWithCredentials(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check dummy users
      final userData = _dummyUsers[email.toLowerCase()];
      if (userData == null || userData['password'] != password) {
        throw Exception('Invalid email or password');
      }

      // Create app user
      _appUser = User(
        id: 'app_${DateTime.now().millisecondsSinceEpoch}',
        name: userData['name']!,
        email: email.toLowerCase(),
        points: 0,
      );

      // Save app user session
      await _authService.saveAppUserSession(_appUser!);
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register new user
  Future<void> registerUser(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user already exists
      if (_dummyUsers.containsKey(email.toLowerCase())) {
        throw Exception('Email already registered');
      }

      // Add to dummy users
      _dummyUsers[email.toLowerCase()] = {
        'name': name,
        'email': email.toLowerCase(),
        'password': password,
      };

      // Create app user
      _appUser = User(
        id: 'app_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email.toLowerCase(),
        points: 0,
      );

      // Save app user session
      await _authService.saveAppUserSession(_appUser!);
      
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Link station with QR code (after app login)
  Future<void> linkStationWithQr(String qrToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.loginWithQrCode(qrToken);
      await loadTransactions();
      await loadUserStats();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with QR code
  Future<void> loginWithQrCode(String qrToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.loginWithQrCode(qrToken);
      await loadTransactions();
      await loadUserStats();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    try {
      _user = await _authService.refreshUserData();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh user data: $e');
      rethrow;
    }
  }

  // Load transactions
  Future<void> loadTransactions({int limit = 50, int offset = 0}) async {
    try {
      _transactions = await _apiService.getTransactions(
        limit: limit,
        offset: offset,
      );
      notifyListeners();
    } catch (e) {
      print('Failed to load transactions: $e');
      rethrow;
    }
  }

  // Load user statistics
  Future<void> loadUserStats() async {
    try {
      _userStats = await _apiService.getUserStats();
      notifyListeners();
    } catch (e) {
      print('Failed to load user stats: $e');
      // Don't rethrow - stats are optional
    }
  }

  // Load redemption options
  Future<List<RedemptionOption>> loadRedemptionOptions() async {
    try {
      return await _apiService.getRedemptionOptions();
    } catch (e) {
      print('Failed to load redemption options: $e');
      rethrow;
    }
  }

  // Redeem points
  Future<void> redeemPoints(RedemptionRequest request) async {
    try {
      await _apiService.redeemPoints(request);
      
      // Refresh user data to get updated balance
      await refreshUserData();
      
      // Reload transactions to show the redemption
      await loadTransactions();
      
      notifyListeners();
    } catch (e) {
      print('Failed to redeem points: $e');
      rethrow;
    }
  }

  // Set base URL
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _authService.saveBaseUrl(url);
    notifyListeners();
  }

  // Connect WebSocket for real-time updates
  void connectWebSocket() {
    if (_user != null) {
      _apiService.connectWebSocket(_user!.id, (data) {
        _handleWebSocketMessage(data);
      });
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(dynamic data) {
    final type = data['type'];
    
    switch (type) {
      case 'transaction':
        // New transaction received
        _handleNewTransaction(data['transaction']);
        break;
      case 'balance_update':
        // Balance updated
        _handleBalanceUpdate(data['balance']);
        break;
      case 'stats_update':
        // Stats updated
        _handleStatsUpdate(data['stats']);
        break;
      default:
        print('Unknown WebSocket message type: $type');
    }
  }

  void _handleNewTransaction(Map<String, dynamic> transactionData) {
    try {
      final transaction = Transaction.fromJson(transactionData);
      _transactions.insert(0, transaction);
      notifyListeners();
    } catch (e) {
      print('Failed to handle new transaction: $e');
    }
  }

  void _handleBalanceUpdate(dynamic balance) {
    if (_user != null) {
      _user = _user!.copyWith(points: (balance as num).toDouble());
      notifyListeners();
    }
  }

  void _handleStatsUpdate(Map<String, dynamic> stats) {
    _userStats = stats;
    notifyListeners();
  }

  // Disconnect WebSocket
  void disconnectWebSocket() {
    _apiService.disconnectWebSocket();
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    disconnectWebSocket();
    _user = null;
    _appUser = null;
    _transactions = [];
    _userStats = null;
    notifyListeners();
  }

  // Check connection to server
  Future<bool> checkConnection() async {
    return await _apiService.checkConnection();
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
