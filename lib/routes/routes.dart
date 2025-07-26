// lib/routes/routes.dart

import 'package:flutter/material.dart';

// Entry category pages
import 'package:veil_chat_application/views/entry/welcome.dart';
import 'package:veil_chat_application/views/entry/register.dart';
import 'package:veil_chat_application/views/entry/login.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';

// Main pages
import 'package:veil_chat_application/views/home/container.dart';
import 'package:veil_chat_application/views/home/history.dart';
import 'package:veil_chat_application/views/home/homepage.dart';
import '../views/home/settings.dart';
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';

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
  static const String aadhaarVerificationWaiting =
      '/aadhaar-verification-waiting';

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
        // verifyOtp: (context) => VerifyOtp(),
        // aboutYou: (context) => const EditInformation(),
        // faceVerification: (context) => const FaceVerification(),
        // profileCreated: (context) => const ProfileCreated(),
        aadhaarVerification: (context) => AadhaarVerification(),
        // aadhaarVerificationWaiting: (context) =>
        //     const AadhaarVerificationWaiting(),

        // Main pages
        homepage: (context) => const HomePageFrame(),
        friendsList: (context) => const HomePage(),
        history: (context) => const History(),
        // chatOptions: (context) => const ChatOptions(),
        // searchingChat: (context) => const SearchingChat(),
        // chatArea: (context) => const ChatArea(),
        settings: (context) => SettingsPage(),
        // profile: (context) => const Profile(),
      };
}
