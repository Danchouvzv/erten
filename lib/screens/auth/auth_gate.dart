import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth_service.dart';
import '../../main.dart';
import 'welcome.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isReady) {
      return const WelcomeScreen();
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBlack,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
                strokeWidth: 2.4,
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          return const WelcomeScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}
