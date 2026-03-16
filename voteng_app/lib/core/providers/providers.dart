import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../../shared/models/models.dart';

// Auth state
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final bool isInitialising; // true while _loadToken() is in flight
  final String? error;

  const AuthState({this.user, this.token, this.isLoading = false, this.isInitialising = true, this.error});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({User? user, String? token, bool? isLoading, bool? isInitialising, String? error}) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      isInitialising: isInitialising ?? this.isInitialising,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  AuthNotifier(this._api) : super(const AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      try {
        final data = await _api.getMe();
        state = AuthState(token: token, user: User.fromJson(data['user']), isInitialising: false);
        return;
      } catch (_) {
        await prefs.remove('auth_token');
      }
    }
    state = state.copyWith(isInitialising: false);
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.register(data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.verifyOtp(phone, otp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      state = AuthState(token: data['token'], user: User.fromJson(data['user']));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(phone, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      state = AuthState(token: data['token'], user: User.fromJson(data['user']));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final msg = e.response?.data;
      if (msg is Map && msg['error'] != null) return msg['error'].toString();
      if (msg is Map && msg['message'] != null) return msg['message'].toString();
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (e is Exception) return e.toString().replaceAll('Exception:', '').trim();
    return 'An error occurred';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

// Vote status provider
final voteStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getVoteStatus();
});

// Candidates provider
final candidatesProvider = FutureProvider.family<List<dynamic>, String>((ref, type) async {
  final api = ref.read(apiServiceProvider);
  return api.getCandidates(type: type);
});

// Analytics providers
final resultsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
  final api = ref.read(apiServiceProvider);
  return api.getResults(type);
});

final thresholdProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getThreshold();
});

final demographicsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
  final api = ref.read(apiServiceProvider);
  return api.getDemographics(type);
});

final turnoutProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getTurnout();
});

final comparisonProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
  final api = ref.read(apiServiceProvider);
  return api.getComparison(type);
});

final stateResultsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
  final api = ref.read(apiServiceProvider);
  return api.getStateResults(type);
});

// Admin providers
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminStats();
});

final electionConfigProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getElectionConfig();
  return data['config'];
});

final adminCandidatesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getCandidates();
  return data;
});
