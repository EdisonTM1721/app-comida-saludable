import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/main_app_shell.dart';
import 'package:emprendedor/presentation/pages/cliente_home_page.dart';
import 'package:emprendedor/presentation/pages/nutricionista_home_page.dart';
import 'package:emprendedor/data/models/business_profile_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _initProfile(BuildContext context, User user) async {
    final profileController = context.read<ProfileController>();
    await profileController.setUserId(user.uid);
  }

  bool _isEntrepreneurProfileComplete(BusinessProfileModel profile) {
    final hasName = profile.name.trim().isNotEmpty &&
        profile.name.trim().toLowerCase() != 'nuevo emprendedor';

    final hasDescription =
        profile.description != null && profile.description!.trim().isNotEmpty;

    final hasAddress =
        profile.address != null && profile.address!.trim().isNotEmpty;

    final hasOpeningHours =
        profile.openingHours != null && profile.openingHours!.trim().isNotEmpty;

    return hasName && hasDescription && hasAddress && hasOpeningHours;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<void>(
          future: _initProfile(context, user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profileController = context.watch<ProfileController>();
            final profile = profileController.businessProfile;

            if (profile == null) {
              return const BusinessProfileEditPage();
            }

            final role = profile.role.trim().toLowerCase();

            if (role == 'cliente') {
              return const ClienteHomePage();
            }

            if (role == 'nutricionista') {
              return const NutricionistaHomePage();
            }

            if (role == 'emprendedor') {
              final isComplete = _isEntrepreneurProfileComplete(profile);

              if (!isComplete) {
                return const BusinessProfileEditPage();
              }

              return const MainAppShell();
            }

            return const MainAppShell();
          },
        );
      },
    );
  }
}