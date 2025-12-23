import 'package:flutter/material.dart';

class ShopperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopper')),
      drawer: Drawer(
        child: ListView(
          children: const [DrawerHeader(child: Text('Menu')), ListTile(title: Text('Jobs')), ListTile(title: Text('History'))],
        ),
      ),
      body: const Center(child: Text('Select a job from the drawer')),
    );
  }
}
