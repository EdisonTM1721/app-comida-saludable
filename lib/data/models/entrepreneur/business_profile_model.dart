import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfileModel {
  String? id;
  String? userId;
  String name;
  String role;
  String? profileImageUrl;
  String? description;
  String? address;
  String? openingHours;
  String? paymentMethods;
  Map<String, dynamic> socialMediaLinks;

  BusinessProfileModel({
    this.id,
    this.userId,
    this.name = '',
    this.role = 'emprendedor',
    this.profileImageUrl,
    this.description,
    this.address,
    this.openingHours,
    this.paymentMethods,
    this.socialMediaLinks = const {},
  });

  factory BusinessProfileModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    return BusinessProfileModel(
      id: doc.id,
      userId: data?['userId'] as String?,
      name: data?['name'] as String? ?? '',
      role: data?['role'] as String? ?? 'emprendedor',
      profileImageUrl: data?['profileImageUrl'] as String?,
      description: data?['description'] as String?,
      address: data?['address'] as String?,
      openingHours: data?['openingHours'] as String?,
      paymentMethods: data?['paymentMethods'] as String?,
      socialMediaLinks: Map<String, dynamic>.from(
        data?['socialMediaLinks'] as Map? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      'role': role,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (openingHours != null) 'openingHours': openingHours,
      if (paymentMethods != null) 'paymentMethods': paymentMethods,
      'socialMediaLinks': socialMediaLinks,
    };
  }

  BusinessProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? role,
    String? profileImageUrl,
    String? description,
    String? address,
    String? openingHours,
    String? paymentMethods,
    Map<String, dynamic>? socialMediaLinks,
  }) {
    return BusinessProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      description: description ?? this.description,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    );
  }
}