import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // ── AUTH ──────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp({required String otp, String email = '', String phone = ''}) async {
    final res = await _dio.post('/auth/verify-otp', data: {
      if (email.isNotEmpty) 'email': email,
      if (phone.isNotEmpty) 'phone': phone,
      'otp': otp,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await _dio.post('/auth/login', data: {'phone': phone, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> resendOtp(String emailOrPhone) async {
    // API accepts either 'email' or 'phone'
    final isEmail = emailOrPhone.contains('@');
    final res = await _dio.post('/auth/resend-otp', data: {
      if (isEmail) 'email': emailOrPhone,
      if (!isEmail) 'phone': emailOrPhone,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  // ── CANDIDATES ──────────────────────────────────────
  Future<List<dynamic>> getCandidates({String? type, int? stateId}) async {
    final res = await _dio.get('/candidates', queryParameters: {
      if (type != null) 'type': type,
      if (stateId != null) 'state_id': stateId,
    });
    return res.data['candidates'];
  }

  Future<List<dynamic>> getParties() async {
    final res = await _dio.get('/candidates/parties/all');
    return res.data['parties'];
  }

  Future<List<dynamic>> getStates() async {
    final res = await _dio.get('/candidates/states/all');
    return res.data['states'];
  }

  Future<List<dynamic>> getLgas(int stateId) async {
    final res = await _dio.get('/candidates/lgas/$stateId');
    return res.data['lgas'];
  }

  // ── VOTES ──────────────────────────────────────────
  Future<Map<String, dynamic>> castVote(int candidateId, String electionType) async {
    final res = await _dio.post('/votes', data: {
      'candidate_id': candidateId,
      'election_type': electionType,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getVoteStatus() async {
    final res = await _dio.get('/votes/status');
    return res.data['status'];
  }

  Future<Map<String, dynamic>> getVoteReceipt(String electionType) async {
    final res = await _dio.get('/votes/receipt/$electionType');
    return res.data['receipt'];
  }

  // ── ANALYTICS ──────────────────────────────────────
  Future<Map<String, dynamic>> getResults(String type) async {
    final res = await _dio.get('/analytics/results', queryParameters: {'type': type});
    return res.data;
  }

  Future<List<dynamic>> getThreshold() async {
    final res = await _dio.get('/analytics/threshold');
    return res.data['threshold'];
  }

  Future<Map<String, dynamic>> getDemographics(String type) async {
    final res = await _dio.get('/analytics/demographics', queryParameters: {'type': type});
    return res.data;
  }

  Future<Map<String, dynamic>> getTurnout() async {
    final res = await _dio.get('/analytics/turnout');
    return res.data;
  }

  Future<Map<String, dynamic>> getComparison(String type) async {
    final res = await _dio.get('/analytics/comparison', queryParameters: {'type': type});
    return res.data;
  }

  Future<Map<String, dynamic>> getStateResults(String type) async {
    final res = await _dio.get('/analytics/state-results', queryParameters: {'type': type});
    return res.data;
  }

  Future<Map<String, dynamic>> getTimeline(String type) async {
    final res = await _dio.get('/analytics/timeline', queryParameters: {'type': type});
    return res.data;
  }

  // ── ADMIN ──────────────────────────────────────────
  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await _dio.get('/admin/stats');
    return res.data;
  }

  Future<Map<String, dynamic>> getElectionConfig() async {
    final res = await _dio.get('/admin/election-config');
    return res.data;
  }

  Future<void> updateElectionConfig(String type, Map<String, dynamic> data) async {
    await _dio.put('/admin/election-config/$type', data: data);
  }

  Future<void> addCandidate(Map<String, dynamic> data) async {
    await _dio.post('/admin/candidates', data: data);
  }

  Future<void> updateCandidate(int id, Map<String, dynamic> data) async {
    await _dio.put('/admin/candidates/$id', data: data);
  }

  Future<void> deleteCandidate(int id) async {
    await _dio.delete('/admin/candidates/$id');
  }

  Future<void> submitActualResults(List<Map<String, dynamic>> results) async {
    await _dio.post('/admin/actual-results', data: {'results': results});
  }

  Future<Map<String, dynamic>> getAdminUsers({bool flaggedOnly = false, int page = 1}) async {
    final res = await _dio.get('/admin/users', queryParameters: {
      if (flaggedOnly) 'flagged': 'true',
      'page': page,
    });
    return res.data;
  }

  Future<void> flagUser(int userId, bool flagged) async {
    await _dio.put('/admin/users/$userId/flag', data: {'flagged': flagged});
  }

  Future<void> sendNotification(String title, String body) async {
    await _dio.post('/admin/notifications', data: {'title': title, 'body': body});
  }

  Future<void> updateSmtpSettings(Map<String, dynamic> settings) async {
    await _dio.put('/admin/smtp-settings', data: settings);
  }
}
