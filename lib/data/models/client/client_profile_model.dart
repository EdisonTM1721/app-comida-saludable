class ClientProfileModel {
  final String? id;
  final String userId;
  final String name;
  final String role;
  final String? phone;
  final String? address;
  final String? dietaryGoal;
  final String? age;

  ClientProfileModel({
    this.id,
    required this.userId,
    required this.name,
    this.role = 'cliente',
    this.phone,
    this.address,
    this.dietaryGoal,
    this.age,
  });

  factory ClientProfileModel.fromMap(Map<String, dynamic> data, String id) {
    return ClientProfileModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: data['role']?.toString() ?? 'cliente',
      phone: data['phone']?.toString(),
      address: data['address']?.toString(),
      dietaryGoal: data['dietaryGoal']?.toString(),
      age: data['age']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'dietaryGoal': dietaryGoal,
      'age': age,
    };
  }

  ClientProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? role,
    String? phone,
    String? address,
    String? dietaryGoal,
    String? age,
  }) {
    return ClientProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dietaryGoal: dietaryGoal ?? this.dietaryGoal,
      age: age ?? this.age,
    );
  }
}