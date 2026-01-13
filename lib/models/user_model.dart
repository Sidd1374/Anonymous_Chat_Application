import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/views/entry/login.dart';

class User {
  final String uid;
  final String email;
  final String fullName;
  final Timestamp createdAt;
  final String? profilePicUrl;
  final String? gender;
  final String? age;
  final List<String>? interests;
  final int? verificationLevel;
  final ChatPreferences? chatPreferences;
  final PrivacySettings? privacySettings;

  User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.profilePicUrl,
    this.gender,
    this.age,
    this.interests,
    this.verificationLevel,
    this.chatPreferences,
    this.privacySettings,
  });

    factory User.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String?;
    if (uid == null) {
      throw FormatException('Missing or null UID in user data');
    }

    dynamic createdAtData = json['createdAt'];
    Timestamp createdAt;

    if (createdAtData is Timestamp) {
      // Data from Firestore
      createdAt = createdAtData;
    } else if (createdAtData is String) {
      // Data from SharedPreferences
      createdAt = Timestamp.fromDate(DateTime.parse(createdAtData));
    } else {
      // Handle case where createdAt is missing or of an unexpected type
      throw FormatException('Invalid or missing createdAt field');
    }

    return User(
      uid: uid,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      createdAt: createdAt,
      profilePicUrl: json['profilePicUrl'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] != null ? json['age'].toString() : null,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      verificationLevel: json['verificationLevel'] as int?,
      chatPreferences: json['chatPreferences'] != null
          ? ChatPreferences.fromJson(
              json['chatPreferences'] as Map<String, dynamic>)
          : null,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(
              json['privacySettings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toDate().toIso8601String(),
      'profilePicUrl': profilePicUrl,
      'gender': gender,
      'age': age,
      'interests': interests,
      'verificationLevel': verificationLevel,
      'chatPreferences': chatPreferences?.toJson(),
      'privacySettings': privacySettings?.toJson(),
    };
  }

  // Save user to SharedPreferences
  static Future<void> saveToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = jsonEncode(user.toJson());
    print('Saving user data to SharedPreferences: $userDataJson');
    await prefs.setString('user_data', userDataJson);
    await prefs.setString('uid', user.uid);
  }

  // Retrieve user from SharedPreferences
  static Future<User?> getFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    print('Retrieved user data from SharedPreferences: $userData');
    if (userData == null) return null;
    try {
      final decodedData = jsonDecode(userData);
      print('Decoded user data: $decodedData');
      final user = User.fromJson(decodedData);
      print('User object from SharedPreferences: ${user.uid}');
      return user;
    } catch (e) {
      // Log the error for debugging, but don't crash the app
      print('Error decoding user data from SharedPreferences: $e');
      // Clear invalid data to prevent future errors
      await prefs.remove('user_data');
      return null;
    }
  }

  // Remove user from SharedPreferences (logout)
  static Future<void> clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('uid');
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
  static Future<Map<String, dynamic>> getProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic savedAge = prefs.get('user_age'); // Use get() to retrieve any type
    return {
      'fullName': prefs.getString('user_fullName'),
      'gender': prefs.getString('user_gender'),
      'age': savedAge != null ? savedAge.toString() : null, // Convert to String if not null
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

class ChatPreferences {
  final String? matchWithGender;
  final int? minAge;
  final int? maxAge;
  final bool? onlyVerified;

  ChatPreferences({
    this.matchWithGender,
    this.minAge,
    this.maxAge,
    this.onlyVerified,
  });

  factory ChatPreferences.fromJson(Map<String, dynamic> json) {
    return ChatPreferences(
      matchWithGender: json['matchWithGender'] as String?,
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
      onlyVerified: json['onlyVerified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchWithGender': matchWithGender,
      'minAge': minAge,
      'maxAge': maxAge,
      'onlyVerified': onlyVerified,
    };
  }
}

class PrivacySettings {
  final bool? showProfilePicToFriends;
  final bool? showProfilePicToStrangers;

  PrivacySettings({
    this.showProfilePicToFriends,
    this.showProfilePicToStrangers,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showProfilePicToFriends: json['showProfilePicToFriends'] as bool?,
      showProfilePicToStrangers: json['showProfilePicToStrangers'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showProfilePicToFriends': showProfilePicToFriends,
      'showProfilePicToStrangers': showProfilePicToStrangers,
    };
  }
}