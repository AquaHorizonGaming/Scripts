import 'package:flutter/material.dart';

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: Drawer(
        child: ListView(
          children: const [DrawerHeader(child: Text('Admin')), ListTile(title: Text('Users')), ListTile(title: Text('Orders'))],
        ),
      ),
      body: const Center(child: Text('Admin controls here')),
    );
  }
}
