import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

const _baseUrl = 'https://api.lostmediastudios.com';

class ApiClient {
  /// Base URL for the FastAPI backend
  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<User?> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['access_token']);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User?> signup(String email, String password) async {
    final response = await _dio.post('/auth/signup', data: {
      'email': email,
      'password': password,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.delete(key: _tokenKey);

  Future<List<Product>> fetchProducts() async {
    final response = await _dio.get('/products/');
    return (response.data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> fetchOrders() async {
    final token = await _storage.read(key: _tokenKey);
    final response = await _dio.get('/orders/',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
