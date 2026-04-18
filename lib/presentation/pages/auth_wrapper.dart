import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/data/models/client_profile_model.dart';
import 'package:emprendedor/data/models/nutritionist_profile_model.dart';

import 'package:emprendedor/data/repositories/business_profile_repository.dart';
import 'package:emprendedor/data/repositories/client_profile_repository.dart';
import 'package:emprendedor/data/repositories/nutritionist_profile_repository.dart';

import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/client_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/nutritionist_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/main_app_shell.dart';
import 'package:emprendedor/presentation/pages/cliente_home_page.dart';
import 'package:emprendedor/presentation/pages/nutricionista_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>?> _loadProfileByRole(String userId) async {
    final businessRepo = BusinessProfileRepository();
    final clientRepo = ClientProfileRepository();
    final nutritionistRepo = NutritionistProfileRepository();

    final BusinessProfileModel? business =
    await businessRepo.getBusinessProfile(userId);
    if (business != null) {
      return {'role': 'emprendedor', 'profile': business};
    }

    final ClientProfileModel? client = await clientRepo.getClientProfile(userId);
    if (client != null) {
      return {'role': 'cliente', 'profile': client};
    }

    final NutritionistProfileModel? nutritionist =
    await nutritionistRepo.getNutritionistProfile(userId);
    if (nutritionist != null) {
      return {'role': 'nutricionista', 'profile': nutritionist};
    }

    return null;
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

  bool _isClientProfileComplete(ClientProfileModel profile) {
    final hasName = profile.name.trim().isNotEmpty &&
        profile.name.trim().toLowerCase() != 'nuevo cliente';
    final hasPhone =
        profile.phone != null && profile.phone!.trim().isNotEmpty;
    final hasAddress =
        profile.address != null && profile.address!.trim().isNotEmpty;
    final hasGoal =
        profile.dietaryGoal != null && profile.dietaryGoal!.trim().isNotEmpty;
    final hasAge = profile.age != null && profile.age!.trim().isNotEmpty;

    return hasName && hasPhone && hasAddress && hasGoal && hasAge;
  }

  bool _isNutritionistProfileComplete(NutritionistProfileModel profile) {
    final hasName = profile.name.trim().isNotEmpty &&
        profile.name.trim().toLowerCase() != 'nuevo nutricionista';
    final hasPhone =
        profile.phone != null && profile.phone!.trim().isNotEmpty;
    final hasSpecialty =
        profile.specialty != null && profile.specialty!.trim().isNotEmpty;
    final hasDescription = profile.professionalDescription != null &&
        profile.professionalDescription!.trim().isNotEmpty;
    final hasMode = profile.consultationMode != null &&
        profile.consultationMode!.trim().isNotEmpty;

    return hasName && hasPhone && hasSpecialty && hasDescription && hasMode;
  }

  @override
  Widget build(BuildContext context) {
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
          future: _loadProfileByRole(user.uid),
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
              final profile = result['profile'] as BusinessProfileModel;

              if (!_isEntrepreneurProfileComplete(profile)) {
                return BusinessProfileEditPage(userId: user.uid);
              }

              return const MainAppShell();
            }

            if (role == 'cliente') {
              final profile = result['profile'] as ClientProfileModel;

              if (!_isClientProfileComplete(profile)) {
                return const ClientProfileEditPage();
              }

              return const ClienteHomePage();
            }

            if (role == 'nutricionista') {
              final profile = result['profile'] as NutritionistProfileModel;

              if (!_isNutritionistProfileComplete(profile)) {
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