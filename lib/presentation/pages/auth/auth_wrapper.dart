import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/presentation/controllers/auth/auth_controller.dart';
import 'package:emprendedor/presentation/pages/auth/login_page.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/home/main_app_shell.dart';
import 'package:emprendedor/presentation/pages/client/home/cliente_home_page.dart';
import 'package:emprendedor/presentation/pages/nutritionist/home/nutricionista_home_page.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/profile/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/client/profile/client_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/nutritionist/profile/nutritionist_profile_edit_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: authController.loadProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final result = snapshot.data;

            if (result == null) {
              return const LoginPage();
            }

            final role = result['role'];

            if (role == 'emprendedor') {
              final profile = result['profile'];

              if (!authController.isEntrepreneurComplete(profile)) {
                return BusinessProfileEditPage(userId: user.uid);
              }

              return const MainAppShell();
            }

            if (role == 'cliente') {
              final profile = result['profile'];

              if (!authController.isClientComplete(profile)) {
                return const ClientProfileEditPage();
              }

              return const ClienteHomePage();
            }

            if (role == 'nutricionista') {
              final profile = result['profile'];

              if (!authController.isNutritionistComplete(profile)) {
                return const NutritionistProfileEditPage();
              }

              return const NutricionistaHomePage();
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}