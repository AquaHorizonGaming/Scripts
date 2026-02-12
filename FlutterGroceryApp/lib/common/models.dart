enum UserRole { customer, shopper, admin }

class User {
  final String id;
  final String email;
  final UserRole role;

  User({required this.id, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      role: UserRole.values.firstWhere(
        (r) => r.name == (json['role'] ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double customerPrice;
  final double shopperPrice;

  Product({required this.id, required this.name, required this.imageUrl, required this.customerPrice, required this.shopperPrice});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['image_url'] ?? '',
      customerPrice: (json['customer_price'] ?? 0).toDouble(),
      shopperPrice: (json['shopper_price'] ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final List<Product> items;
  final DateTime scheduledFor;
  final String status;

  Order({required this.id, required this.items, required this.scheduledFor, required this.status});

  factory Order.fromJson(Map<String, dynamic> json) {
    final products = (json['items'] as List? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    return Order(
      id: json['id'].toString(),
      items: products,
      scheduledFor: DateTime.parse(json['scheduled_for']),
      status: json['status'] ?? 'pending',
    );
  }
}
