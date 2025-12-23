import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

class ApiClient {
  /// Base URL for the FastAPI backend
  final Dio _dio =
      Dio(BaseOptions(baseUrl: 'https://api.lostmediastudios.com'));
  final _storage = const FlutterSecureStorage();

  Future<User?> login(String email, String password) async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(seconds: 1));
    // simple role detection based on email for demo
    if (email.contains('shopper')) {
      return User(id: '1', email: email, role: UserRole.shopper);
    } else if (email.contains('admin')) {
      return User(id: '2', email: email, role: UserRole.admin);
    }
    return User(id: '3', email: email, role: UserRole.customer);
  }

  Future<List<Product>> fetchProducts() async {
    // TODO: Fetch from backend
    return [];
  }

  Future<List<Order>> fetchOrders(UserRole role) async {
    // TODO: role-based endpoint
    return [];
  }
}
