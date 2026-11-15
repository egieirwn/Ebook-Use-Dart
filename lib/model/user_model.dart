import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String phone;
  final String dob;
  final String address;
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName = '',
    this.role = 'user',
    this.phone = '',
    this.dob = '',
    this.address = '',
    this.photoUrl = '',
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'] ?? '',
      dob: data['dob'] ?? '',
      address: data['address'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'] ?? '',
      dob: data['dob'] ?? '',
      address: data['address'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'dob': dob,
      'address': address,
      'photoUrl': photoUrl,
    };
  }
}
