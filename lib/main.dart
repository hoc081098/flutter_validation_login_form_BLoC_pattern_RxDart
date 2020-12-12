import 'package:flutter/material.dart';

import 'login/login_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter BLoC login form',
      theme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}
