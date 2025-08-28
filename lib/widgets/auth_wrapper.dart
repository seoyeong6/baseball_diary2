import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/auth_screen.dart';
import '../main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) {
        final authService = AuthService();

        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.isAuthenticated) {
          return const MainNavigationScreen();
        }

        return const AuthScreen();
      },
    );
  }
}