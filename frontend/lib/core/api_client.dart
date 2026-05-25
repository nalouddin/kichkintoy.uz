import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Backend API bilan ishlovchi asosiy klient.
class ApiClient {
  // ==== BACKEND URL ====
  // Mahalliy emulator:     (hech narsa kerak emas)
  // Real WiFi telefon:     flutter run --dart-define=SERVER_IP=192.168.1.100
  // Production APK/web:    flutter build apk --dart-define=SERVER_URL=https://sizningdomen.uz
  //                        flutter build web  (domen avtomatik olinadi, SERVER_URL shart emas)
  static const String _serverUrl = String.fromEnvironment('SERVER_URL', defaultValue: '');
  static const String _serverIp = String.fromEnvironment('SERVER_IP', defaultValue: '');

  static String get _origin {
    if (_serverUrl.isNotEmpty) return _serverUrl;
    if (_serverIp.isNotEmpty) return 'http://$_serverIp:8000';
    if (kIsWeb) return Uri.base.origin;
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String get baseUrl => '$_origin/api/v1';
  static String get wsUrl {
    final wsOrigin = _origin
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$wsOrigin/api/v1/chat/ws';
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final options = error.requestOptions;
            final token = await _storage.read(key: 'access_token');
            options.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '$baseUrl/auth/refresh',
        queryParameters: {'refresh_token': refreshToken},
      );
      await _storage.write(
          key: 'access_token', value: response.data['access_token']);
      await _storage.write(
          key: 'refresh_token', value: response.data['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ============ AUTH ============

  Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'full_name': fullName,
      'role': role,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'login': login,
      'password': password,
    });
    await _storage.write(
        key: 'access_token', value: response.data['access_token']);
    await _storage.write(
        key: 'refresh_token', value: response.data['refresh_token']);
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ============ LESSONS ============

  Future<List<dynamic>> getLessons({int? ageGroup, String? category}) async {
    final response = await _dio.get('/lessons/', queryParameters: {
      if (ageGroup != null) 'age_group': ageGroup,
      if (category != null) 'category': category,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> submitProgress({
    required String childId,
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
    int stars = 0,
  }) async {
    final response = await _dio.post('/lessons/progress', data: {
      'child_id': childId,
      'lesson_id': lessonId,
      'score': score,
      'time_spent_seconds': timeSpentSeconds,
      'stars': stars,
    });
    return response.data;
  }

  // ============ CHILDREN ============

  Future<Map<String, dynamic>> getMyChildProfile() async {
    final response = await _dio.get('/children/me');
    return response.data;
  }

  Future<Map<String, dynamic>> addChild({
    required String fullName,
    required String birthDate, // YYYY-MM-DD
    String? nickname,
    required String password,
  }) async {
    final response = await _dio.post('/children/', data: {
      'full_name': fullName,
      'birth_date': birthDate,
      if (nickname != null) 'nickname': nickname,
      'password': password,
    });
    return response.data;
  }

  Future<List<dynamic>> getMyChildren() async {
    final response = await _dio.get('/children/my');
    return response.data;
  }

  Future<Map<String, dynamic>> getChild(String childId) async {
    final response = await _dio.get('/children/$childId');
    return response.data;
  }

  Future<Map<String, dynamic>> getChildStats(String childId) async {
    final response = await _dio.get('/children/$childId/stats');
    return response.data;
  }

  Future<void> deleteChild(String childId) async {
    await _dio.delete('/children/$childId');
  }

  // ============ GROUPS (Pedagog) ============

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required int ageGroup,
    String? description,
  }) async {
    final response = await _dio.post('/groups/', data: {
      'name': name,
      'age_group': ageGroup,
      if (description != null) 'description': description,
    });
    return response.data;
  }

  Future<List<dynamic>> getMyGroups() async {
    final response = await _dio.get('/groups/my');
    return response.data;
  }

  Future<List<dynamic>> getGroupChildren(String groupId) async {
    final response = await _dio.get('/groups/$groupId/children');
    return response.data;
  }

  Future<void> addChildToGroup(String groupId, String childId) async {
    await _dio.post('/groups/$groupId/children', data: {'child_id': childId});
  }

  Future<List<dynamic>> getAllGroups() async {
    final response = await _dio.get('/groups/');
    return response.data;
  }

  Future<Map<String, dynamic>> assignChildToGroup(
      String childId, String? groupId) async {
    final response = await _dio.patch('/children/$childId/group',
        data: {'group_id': groupId});
    return response.data;
  }

  Future<void> deleteGroup(String groupId) async {
    await _dio.delete('/groups/$groupId');
  }

  // ============ ASSIGNMENTS ============

  Future<Map<String, dynamic>> createAssignment({
    required String groupId,
    required String lessonId,
    required String title,
    String? instructions,
    String? dueDate,
  }) async {
    final response = await _dio.post('/assignments/', data: {
      'group_id': groupId,
      'lesson_id': lessonId,
      'title': title,
      if (instructions != null) 'instructions': instructions,
      if (dueDate != null) 'due_date': dueDate,
    });
    return response.data;
  }

  Future<List<dynamic>> getMyAssignments() async {
    final response = await _dio.get('/assignments/my');
    return response.data;
  }

  Future<List<dynamic>> getGroupAssignments(String groupId) async {
    final response = await _dio.get('/assignments/group/$groupId');
    return response.data;
  }

  // ============ CONTENT ============

  Future<List<dynamic>> getStories({int? ageGroup, String? category}) async {
    final response = await _dio.get('/content/stories/', queryParameters: {
      if (ageGroup != null) 'age_group': ageGroup,
      if (category != null) 'category': category,
    });
    return response.data;
  }

  Future<List<dynamic>> getRecommendations({
    String? category,
    int? ageGroup,
  }) async {
    final response =
        await _dio.get('/content/recommendations/', queryParameters: {
      if (category != null) 'category': category,
      if (ageGroup != null) 'age_group': ageGroup,
    });
    return response.data;
  }

  // ============ ADMIN ============

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await _dio.get('/admin/stats');
    return response.data;
  }

  Future<List<dynamic>> getAdminUsers({String? role}) async {
    final response = await _dio.get('/admin/users', queryParameters: {
      if (role != null) 'role': role,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> toggleUserActive(String userId) async {
    final response = await _dio.patch('/admin/users/$userId/toggle');
    return response.data;
  }

  Future<void> deleteLesson(String lessonId) async {
    await _dio.delete('/lessons/$lessonId');
  }

  Future<Map<String, dynamic>> createStory({
    required String title,
    required String content,
    required String category,
    required int ageGroup,
    String? description,
    String? author,
  }) async {
    final response = await _dio.post('/content/stories/', data: {
      'title': title,
      'content': content,
      'category': category,
      'age_group': ageGroup,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateStory(
    String storyId, {
    String? title,
    String? content,
    String? category,
    int? ageGroup,
    String? description,
    String? author,
    bool? isActive,
  }) async {
    final response = await _dio.put('/content/stories/$storyId', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (ageGroup != null) 'age_group': ageGroup,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (isActive != null) 'is_active': isActive,
    });
    return response.data;
  }

  Future<void> deleteStory(String storyId) async {
    await _dio.delete('/content/stories/$storyId');
  }

  Future<Map<String, dynamic>> createRecommendation({
    required String title,
    required String content,
    required String category,
    int? ageGroup,
    String? author,
  }) async {
    final response = await _dio.post('/content/recommendations/', data: {
      'title': title,
      'content': content,
      'category': category,
      if (ageGroup != null) 'age_group': ageGroup,
      if (author != null) 'author': author,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateRecommendation(
    String recId, {
    String? title,
    String? content,
    String? category,
    int? ageGroup,
    String? author,
    bool? isActive,
  }) async {
    final response = await _dio.put('/content/recommendations/$recId', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (ageGroup != null) 'age_group': ageGroup,
      if (author != null) 'author': author,
      if (isActive != null) 'is_active': isActive,
    });
    return response.data;
  }

  Future<void> deleteRecommendation(String recId) async {
    await _dio.delete('/content/recommendations/$recId');
  }

  // ============ ADMIN: foydalanuvchi yaratish / o'chirish ============

  Future<Map<String, dynamic>> adminCreateUser({
    required String fullName,
    required String role,
    String? phone,
    String? email,
    required String password,
  }) async {
    final response = await _dio.post('/admin/users', data: {
      'full_name': fullName,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> adminCreateChild({
    required String fullName,
    required String birthDate,
    required String password,
    required String parentId,
    String? nickname,
  }) async {
    final response = await _dio.post('/admin/children', data: {
      'full_name': fullName,
      'birth_date': birthDate,
      'password': password,
      'parent_id': parentId,
      if (nickname != null) 'nickname': nickname,
    });
    return response.data;
  }

  Future<void> adminDeleteUser(String userId) async {
    await _dio.delete('/admin/users/$userId');
  }

  // ============ CHAT ============

  Future<List<dynamic>> getChatContacts() async {
    final response = await _dio.get('/chat/contacts');
    return response.data;
  }

  Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('/chat/conversations');
    return response.data;
  }

  Future<List<dynamic>> getMessages(String otherUserId) async {
    final response = await _dio.get('/chat/messages/$otherUserId');
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    final response = await _dio.post('/chat/messages', data: {
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
    });
    return response.data;
  }
}
