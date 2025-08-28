import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _toggleAuthMode() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login'),
              onSignUpTap: _toggleAuthMode,
            )
          : RegisterScreen(
              key: const ValueKey('register'),
              onSignInTap: _toggleAuthMode,
            ),
    );
  }
}