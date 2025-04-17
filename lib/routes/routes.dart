// lib/routes/routes.dart

import 'package:flutter/material.dart';

// Entry category pages
import 'package:veil_chat_application/views/entry/welcome.dart';
import 'package:veil_chat_application/views/entry/register.dart';
import 'package:veil_chat_application/views/entry/login.dart';
import 'package:veil_chat_application/views/entry/verify_otp.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';
import 'package:veil_chat_application/views/entry/face_verification.dart';
import 'package:veil_chat_application/views/entry/profile_created.dart';
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';
import 'package:veil_chat_application/views/entry/aadhaar_verification_waiting.dart';

// Main pages
import 'package:veil_chat_application/views/home/container.dart';
import 'package:veil_chat_application/views/home/friends_list.dart';
import 'package:veil_chat_application/views/home/history.dart';
import 'package:veil_chat_application/views/home/chat_options.dart';
import 'package:veil_chat_application/views/home/homepage.dart';
import 'package:veil_chat_application/views/home/searching_chat.dart';
import 'package:veil_chat_application/views/home/chat_area.dart';
import 'package:veil_chat_application/views/home/settings.dart';
import 'package:veil_chat_application/views/home/profile.dart';

class AppRoutes {
  // Entry routes
  static const String welcome = '/welcome';
  static const String register = '/register';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String aboutYou = '/about-you';
  static const String faceVerification = '/face-verification';
  static const String profileCreated = '/profile-created';
  static const String aadhaarVerification = '/aadhaar-verification';
  static const String aadhaarVerificationWaiting = '/aadhaar-verification-waiting';

  // Main routes
  static const String homepage = '/homepage';
  static const String friendsList = '/friends-list';
  static const String history = '/history';
  static const String chatOptions = '/chat-options';
  static const String searchingChat = '/searching-chat';
  static const String chatArea = '/chat-area';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    // Entry category
    welcome: (context) => const Welcome(),
    register: (context) => const Register(),
    login: (context) => const Login(),
    verifyOtp: (context) => const VerifyOtp(),
    aboutYou: (context) => const AboutYou(),
    faceVerification: (context) => const FaceVerification(),
    profileCreated: (context) => const ProfileCreated(),
    aadhaarVerification: (context) => const AadhaarVerification(),
    aadhaarVerificationWaiting: (context) => const AadhaarVerificationWaiting(),

    // Main pages
    homepage: (context) => const FriendsList(),
    friendsList: (context) => const FriendsList(),
    history: (context) => const History(),
    chatOptions: (context) => const ChatOptions(),
    searchingChat: (context) => const SearchingChat(),
    chatArea: (context) => const ChatArea(),
    settings: (context) => const Settings(),
    profile: (context) => const Profile(),
  };
}
