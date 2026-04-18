class NutritionistProfileModel {
  String? id;
  String userId;
  String name;
  String role;
  String? phone;
  String? specialty;
  String? professionalDescription;
  String? consultationMode;

  NutritionistProfileModel({
    this.id,
    required this.userId,
    required this.name,
    this.role = 'nutricionista',
    this.phone,
    this.specialty,
    this.professionalDescription,
    this.consultationMode,
  });

  factory NutritionistProfileModel.fromMap(
      Map<String, dynamic> data, String id) {
    return NutritionistProfileModel(
      id: id,
      userId: data['userId'],
      name: data['name'] ?? '',
      role: data['role'] ?? 'nutricionista',
      phone: data['phone'],
      specialty: data['specialty'],
      professionalDescription: data['professionalDescription'],
      consultationMode: data['consultationMode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'phone': phone,
      'specialty': specialty,
      'professionalDescription': professionalDescription,
      'consultationMode': consultationMode,
    };
  }
}