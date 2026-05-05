import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_state.dart';
import 'api_providers.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  static const _storage = FlutterSecureStorage();

  @override
  AuthStatus build() {
    _checkStoredToken();
    return AuthStatus.loading;
  }

  Future<void> _checkStoredToken() async {
    final token = await _storage.read(key: 'access_token');
    state = token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<String?> register(String email, String password) async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/auth/register', data: {'email': email, 'password': password});
      final tokens = AuthTokens.fromJson(resp.data as Map<String, dynamic>);
      await _saveTokens(tokens);
      state = AuthStatus.authenticated;
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post('/auth/login', data: {'email': email, 'password': password});
      final tokens = AuthTokens.fromJson(resp.data as Map<String, dynamic>);
      await _saveTokens(tokens);
      state = AuthStatus.authenticated;
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = AuthStatus.unauthenticated;
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token', value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
  }

  String _errorMessage(Object e) {
    if (e.toString().contains('409')) return 'Email already registered.';
    if (e.toString().contains('401')) return 'Invalid email or password.';
    return 'Connection error. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
