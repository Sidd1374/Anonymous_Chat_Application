import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String email;
  final String fullName;
  final String password;
  final String profilePic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.email,
    required this.fullName,
    required this.password,
    this.profilePic = "",
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      password: json['password'] as String,
      profilePic: json['profilePic'] ?? "",
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'password': password,
      'profilePic': profilePic,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Save user to SharedPreferences
  static Future<void> saveToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // Retrieve user from SharedPreferences
  static Future<User?> getFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData));
  }

  // Remove user from SharedPreferences (logout)
  static Future<void> clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}
