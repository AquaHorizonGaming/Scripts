import 'package:flutter/material.dart';
import '../common/api_client.dart';
import '../common/models.dart';

class CustomerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Customer'), bottom: const TabBar(tabs: [Tab(text: 'Browse'), Tab(text: 'Cart'), Tab(text: 'Orders')])),
        body: TabBarView(children: [BrowseView(), CartView(), OrderHistoryView()]),
      ),
    );
  }
}

class BrowseView extends StatelessWidget {
  final api = ApiClient();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: api.fetchProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        return ListView(
          children: products.map((p) => ListTile(title: Text(p.name))).toList(),
        );
      },
    );
  }
}

class CartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Cart'));
  }
}

class OrderHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Orders'));
  }
}
