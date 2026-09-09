import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../models/todo.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Owns the session token (secure storage) and every backend call.
/// Kept as one plain class instead of a state-management package —
/// this app has one screen's worth of state, a Provider/Riverpod layer
/// would be pure overhead right now.
class TodoRepository {
  static const _tokenKey = 'session_token';
  final _storage = const FlutterSecureStorage();
  String? _token;

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  /// Call once at app startup. Reads a stored token, or — on first
  /// launch only — creates a new anonymous session and stores it.
  Future<void> ensureSession() async {
    _token = await _storage.read(key: _tokenKey);
    if (_token != null) return;

    final res = await http.post(_uri('/anonymous-session'), headers: _headers(auth: false));
    _checkStatus(res);
    _token = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
    await _storage.write(key: _tokenKey, value: _token!);
  }

  Future<List<Todo>> listTodos() async {
    final res = await http.get(_uri('/todos'), headers: _headers());
    _checkStatus(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Todo> createTodo(String title, String? description) async {
    final res = await http.post(
      _uri('/todos'),
      headers: _headers(),
      body: jsonEncode({'title': title, 'description': description}),
    );
    _checkStatus(res);
    return Todo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Todo> setCompleted(String id, bool completed) async {
    final res = await http.patch(
      _uri('/todos/$id'),
      headers: _headers(),
      body: jsonEncode({'completed': completed}),
    );
    _checkStatus(res);
    return Todo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteTodo(String id) async {
    final res = await http.delete(_uri('/todos/$id'), headers: _headers());
    _checkStatus(res);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      String message = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        // response wasn't JSON — fall back to raw body
      }
      throw ApiException(res.statusCode, message);
    }
  }
}
