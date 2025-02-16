import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isOnline,
  });

  /// 🔹 **Factory Constructor to Create `UserModel` from Firestore**
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      isOnline: data['isOnline'] ?? false,
    );
  }

  /// 🔹 **Convert JSON to `UserModel` (for SharedPreferences)**
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  /// 🔹 **Convert `UserModel` to JSON (for SharedPreferences)**
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isOnline': isOnline,
    };
  }
}
