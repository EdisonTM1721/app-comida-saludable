class ClientProfileModel {
  String? id;
  String userId;
  String name;
  String role;
  String? phone;
  String? address;
  String? dietaryGoal;
  String? age;

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
      userId: data['userId'],
      name: data['name'] ?? '',
      role: data['role'] ?? 'cliente',
      phone: data['phone'],
      address: data['address'],
      dietaryGoal: data['dietaryGoal'],
      age: data['age'],
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
}