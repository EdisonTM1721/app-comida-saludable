import 'package:flutter/material.dart';

import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/data/models/client_profile_model.dart';
import 'package:emprendedor/data/models/nutritionist_profile_model.dart';

import 'package:emprendedor/data/repositories/business_profile_repository.dart';
import 'package:emprendedor/data/repositories/client_profile_repository.dart';
import 'package:emprendedor/data/repositories/nutritionist_profile_repository.dart';

class AuthController {
  final _businessRepo = BusinessProfileRepository();
  final _clientRepo = ClientProfileRepository();
  final _nutritionistRepo = NutritionistProfileRepository();

  Future<Map<String, dynamic>?> loadProfile(String userId) async {
    final business = await _businessRepo.getBusinessProfile(userId);
    if (business != null) {
      return {'role': 'emprendedor', 'profile': business};
    }

    final client = await _clientRepo.getClientProfile(userId);
    if (client != null) {
      return {'role': 'cliente', 'profile': client};
    }

    final nutritionist =
    await _nutritionistRepo.getNutritionistProfile(userId);
    if (nutritionist != null) {
      return {'role': 'nutricionista', 'profile': nutritionist};
    }

    return null;
  }

  bool isEntrepreneurComplete(BusinessProfileModel profile) {
    return profile.name.trim().isNotEmpty &&
        profile.description?.trim().isNotEmpty == true &&
        profile.address?.trim().isNotEmpty == true &&
        profile.openingHours?.trim().isNotEmpty == true;
  }

  bool isClientComplete(ClientProfileModel profile) {
    return profile.name.trim().isNotEmpty &&
        profile.phone?.trim().isNotEmpty == true &&
        profile.address?.trim().isNotEmpty == true &&
        profile.dietaryGoal?.trim().isNotEmpty == true &&
        profile.age?.trim().isNotEmpty == true;
  }

  bool isNutritionistComplete(NutritionistProfileModel profile) {
    return profile.name.trim().isNotEmpty &&
        profile.phone?.trim().isNotEmpty == true &&
        profile.specialty?.trim().isNotEmpty == true &&
        profile.professionalDescription?.trim().isNotEmpty == true &&
        profile.consultationMode?.trim().isNotEmpty == true;
  }
}