enum UserRole { customer, shopper, admin }

class User {
  final String id;
  final String email;
  final UserRole role;

  User({required this.id, required this.email, required this.role});
}

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double customerPrice;
  final double shopperPrice;

  Product({required this.id, required this.name, required this.imageUrl, required this.customerPrice, required this.shopperPrice});
}

class Order {
  final String id;
  final List<Product> items;
  final DateTime scheduledFor;
  final String status;

  Order({required this.id, required this.items, required this.scheduledFor, required this.status});
}
