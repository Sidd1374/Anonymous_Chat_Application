import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String fullName;
  final Timestamp? createdAt;
  final String? profilePicUrl;
  final String? gender;
  final int? age;
  final List<String>? interests;
  final int? verificationLevel;
  final ChatPreferences? chatPreferences;
  final PrivacySettings? privacySettings;

  User({
    required this.uid,
    required this.email,
    required this.fullName,
    this.createdAt,
    this.profilePicUrl,
    this.gender,
    this.age,
    this.interests,
    this.verificationLevel,
    this.chatPreferences,
    this.privacySettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      createdAt: json['createdAt'] as Timestamp?,
      profilePicUrl: json['profilePicUrl'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList(),
      verificationLevel: json['verificationLevel'] as int?,
      chatPreferences: json['chatPreferences'] != null
          ? ChatPreferences.fromJson(json['chatPreferences'] as Map<String, dynamic>)
          : null,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(json['privacySettings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt,
      'profilePicUrl': profilePicUrl,
      'gender': gender,
      'age': age,
      'interests': interests,
      'verificationLevel': verificationLevel,
      'chatPreferences': chatPreferences?.toJson(),
      'privacySettings': privacySettings?.toJson(),
    };
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