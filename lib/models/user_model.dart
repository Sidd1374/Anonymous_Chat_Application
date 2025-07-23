import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/entry/login.dart';

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

  // Save name, age, and gender to SharedPreferences
  static Future<void> saveProfileDetails({
    required String fullName,
    required String gender,
    required String age,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullName', fullName);
    await prefs.setString('user_gender', gender);
    await prefs.setString('user_age', age);
  }

  // Retrieve name, age, and gender from SharedPreferences
  static Future<Map<String, String?>> getProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString('user_fullName'),
      'gender': prefs.getString('user_gender'),
      'age': prefs.getString('user_age'),
    };
  }

  static Future<String?> saveProfileImageLocally(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final userDir = Directory('${appDir.path}/Assets/User');
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    final fileName = path.basename(imageFile.path);
    final savedImage = await imageFile.copy('${userDir.path}/$fileName');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', savedImage.path);
    return savedImage.path;
  }

  /// Logs out the user by clearing all SharedPreferences data
  /// and navigating to the login page.
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears ALL data saved by your app in SharedPreferences

    // After clearing data, navigate to the login page.
    // pushAndRemoveUntil ensures the user cannot go back to previous authenticated screens.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              const Login()), // Replace LoginPage() with your actual login page widget
      (Route<dynamic> route) => false, // This predicate removes all previous routes
    );
  }
}
