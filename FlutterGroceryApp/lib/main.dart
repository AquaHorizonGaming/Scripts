import 'package:flutter/material.dart';
import 'common/api_client.dart';
import 'common/models.dart';
import 'customer/customer_app.dart';
import 'shopper/shopper_app.dart';
import 'admin/admin_app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Delivery',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final api = ApiClient();
    final user = await api.login(_emailController.text, _passwordController.text);
    setState(() => _loading = false);

    if (user != null) {
      switch (user.role) {
        case UserRole.customer:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerApp()));
          break;
        case UserRole.shopper:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ShopperApp()));
          break;
        case UserRole.admin:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminApp()));
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? CircularProgressIndicator() : Text('Login')),
          ],
        ),
      ),
    );
  }
}
