import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/services/firestore_service.dart';
import 'package:veil_chat_application/views/entry/profile_created.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/services/cloudinary_service.dart';

class ChatSettingsPage extends StatefulWidget {
  final int verificationLevel;
  final bool isBottomSheet;
  final ScrollController? scrollController;
  final bool isOnboarding;
  // User profile data for onboarding flow
  final String? profileImage;
  final String? userName;
  final String? userGender;
  final String? userAge;

  const ChatSettingsPage({
    super.key,
    this.verificationLevel = 0,
    this.isBottomSheet = false,
    this.scrollController,
    this.isOnboarding = false,
    this.profileImage,
    this.userName,
    this.userGender,
    this.userAge,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Selected interests (liked = primary, disliked = red)
  final Set<String> _likedInterests = {};
  final Set<String> _dislikedInterests = {};

  // Max limits
  static const int _maxLikes = 5;
  static const int _maxDislikes = 5;
  static const int _minLikesOnboarding = 3;
  static const int _minDislikesOnboarding = 3;

  // Age range
  RangeValues _ageRange = const RangeValues(18, 40);
  static const double _minAgeLimit = 18;
  static const double _maxAgeLimit = 60;

  // Toggles
  bool _oppositeGenderOnly = false;
  bool _verifiedUsersOnly = false;

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // User data
  mymodel.User? _user;

  // Hardcoded pool of interests
  static const List<String> _interestPool = [
    '🎮 Gaming',
    '🎵 Music',
    '📚 Reading',
    '🎬 Movies',
    '🏋️ Fitness',
    '🍳 Cooking',
    '✈️ Travel',
    '📷 Photography',
    '🎨 Art',
    '💻 Technology',
    '🌱 Nature',
    '🧘 Meditation',
    '🎭 Theater',
    '⚽ Sports',
    '🐕 Pets',
    '🎲 Board Games',
    '📝 Writing',
    '🎸 Instruments',
    '🌍 Languages',
    '🔬 Science',
    '🧠 Psychology',
    '💼 Business',
    '🎤 Karaoke',
    '🍿 Anime',
    '📱 Social Media',
    '🏕️ Camping',
    '🎯 Darts',
    '🧩 Puzzles',
    '🎪 Comedy',
    '👗 Fashion',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize age range immediately for onboarding (from widget params)
    if (widget.isOnboarding &&
        widget.userAge != null &&
        widget.userAge!.isNotEmpty) {
      final userAge = int.tryParse(widget.userAge!) ?? 25;
      double minAge = (userAge - 2).toDouble();
      double maxAge = (userAge + 3).toDouble();

      if (minAge < _minAgeLimit) {
        minAge = _minAgeLimit;
        maxAge = (_minAgeLimit + 5).clamp(_minAgeLimit, _maxAgeLimit);
      } else if (maxAge > _maxAgeLimit) {
        maxAge = _maxAgeLimit;
        minAge = (_maxAgeLimit - 5).clamp(_minAgeLimit, _maxAgeLimit);
      }

      _ageRange = RangeValues(minAge, maxAge);
      debugPrint(
          '[ChatSettings] initState: Set age range from widget.userAge=$userAge to $minAge-$maxAge');
    }

    _initAnimations();
    _loadSavedPreferences();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final user = await mymodel.User.getFromPrefs();
      if (user != null && mounted) {
        setState(() {
          _user = user;
          if (user.chatPreferences != null && !widget.isOnboarding) {
            // Load existing preferences only if not onboarding
            _likedInterests.addAll(user.chatPreferences!.interests ?? []);
            _dislikedInterests.addAll(user.chatPreferences!.dealBreakers ?? []);
            _ageRange = RangeValues(
              (user.chatPreferences!.minAge ?? 18)
                  .toDouble()
                  .clamp(_minAgeLimit, _maxAgeLimit),
              (user.chatPreferences!.maxAge ?? 40)
                  .toDouble()
                  .clamp(_minAgeLimit, _maxAgeLimit),
            );
            _oppositeGenderOnly = user.chatPreferences!.matchWithGender != null;
            _verifiedUsersOnly = user.chatPreferences!.onlyVerified ?? false;
          }

          // Set recommended age range based on user's age during onboarding
          if (widget.isOnboarding) {
            final userAgeStr = widget.userAge ?? user.age;
            debugPrint('[ChatSettings] Onboarding: userAge = $userAgeStr');

            int userAge = 25; // Default fallback
            if (userAgeStr != null && userAgeStr.isNotEmpty) {
              userAge = int.tryParse(userAgeStr) ?? 25;
            }

            // Calculate a 5-year range with user's age roughly in the middle
            double minAge = (userAge - 2).toDouble();
            double maxAge = (userAge + 3).toDouble();

            // Handle edge cases at boundaries
            if (minAge < _minAgeLimit) {
              // User is near minimum age (e.g., 18-20)
              minAge = _minAgeLimit;
              maxAge = (_minAgeLimit + 5).clamp(_minAgeLimit, _maxAgeLimit);
            } else if (maxAge > _maxAgeLimit) {
              // User is near maximum age
              maxAge = _maxAgeLimit;
              minAge = (_maxAgeLimit - 5).clamp(_minAgeLimit, _maxAgeLimit);
            }

            _ageRange = RangeValues(minAge, maxAge);
            debugPrint('[ChatSettings] Set age range: $minAge - $maxAge');
          }

          _isLoading = false;
        });
      } else {
        if (widget.isOnboarding) {
          // Try to get lightweight profile details (saved during onboarding)
          final profile = await mymodel.User.getProfileDetails();
          final userAgeStr = widget.userAge ?? profile['age'];
          debugPrint(
              '[ChatSettings] No full user prefs found. profile age = $userAgeStr');

          int userAge = 25;
          if (userAgeStr != null && userAgeStr.toString().isNotEmpty) {
            userAge = int.tryParse(userAgeStr.toString()) ?? 25;
          }

          double minAge = (userAge - 2).toDouble();
          double maxAge = (userAge + 3).toDouble();

          // Handle edge cases at boundaries
          if (minAge < _minAgeLimit) {
            minAge = _minAgeLimit;
            maxAge = (_minAgeLimit + 5).clamp(_minAgeLimit, _maxAgeLimit);
          } else if (maxAge > _maxAgeLimit) {
            maxAge = _maxAgeLimit;
            minAge = (_maxAgeLimit - 5).clamp(_minAgeLimit, _maxAgeLimit);
          }

          setState(() {
            _ageRange = RangeValues(minAge, maxAge);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('[ChatSettings] Error loading preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_user == null) {
      // Onboarding path: construct a minimal user from saved lightweight profile or Firebase Auth
      final prefs = await SharedPreferences.getInstance();
      final profile = await mymodel.User.getProfileDetails();
      final uid =
          prefs.getString('uid') ?? FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        debugPrint(
            '[ChatSettings] No UID found for onboarding user; cannot save preferences.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unable to save preferences: missing user ID'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

        final resolvedName = widget.userName ?? profile['fullName'] ?? '';
        final resolvedGender = widget.userGender ?? profile['gender'];
        final resolvedAge = widget.userAge ?? profile['age']?.toString();
        // Fallback to saved local profile image path if widget.profileImage is null
        String? resolvedProfileImage = widget.profileImage;
        resolvedProfileImage ??= prefs.getString('profile_image_path');

        // Retrieve location from profile first, then prefs
        final String? resolvedLocation = profile['location'] ?? prefs.getString('user_location');
        final double? resolvedLat = profile['latitude'] ?? prefs.getDouble('user_latitude');
        final double? resolvedLng = profile['longitude'] ?? prefs.getDouble('user_longitude');

        _user = mymodel.User(
        uid: uid,
        email: prefs.getString('user_data') != null
          ? (jsonDecode(prefs.getString('user_data')!)
              as Map<String, dynamic>)['email'] ??
            ''
          : '',
        fullName: resolvedName,
        createdAt: Timestamp.now(),
        profilePicUrl: resolvedProfileImage,
        gender: resolvedGender,
        age: resolvedAge,
        interests: const [],
        verificationLevel: widget.verificationLevel,
        chatPreferences: null,
        privacySettings: mymodel.PrivacySettings(
          showProfilePicToFriends: true, showProfilePicToStrangers: false),
        location: resolvedLocation,
        latitude: resolvedLat,
        longitude: resolvedLng,
        locationUpdatedAt: Timestamp.now(),
        );

      debugPrint(
          '[ChatSettings] Built minimal onboarding user: uid=$uid, name=$resolvedName, age=$resolvedAge, gender=$resolvedGender, location=$resolvedLocation');
    }

    // Validate minimum interests/dislikes (required for all users)
    if (_likedInterests.length < _minLikesOnboarding ||
        _dislikedInterests.length < _minDislikesOnboarding) {
      final mediaQuery = MediaQuery.of(context);
      final topPadding = mediaQuery.padding.top; // Status bar / notch height
      final bottomPadding =
          mediaQuery.padding.bottom; // Navigation buttons height

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'You need to select minimum 3 interests and 3 dislikes to continue',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            // Position at top: total height - top safe area - snackbar height estimate - some padding
            bottom: mediaQuery.size.height - topPadding - bottomPadding - 120,
            left: 16.w,
            right: 16.w,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Handle Profile Image Upload (only for onboarding or if image changed)
      String? finalProfilePicUrl = _user?.profilePicUrl;

      // During onboarding, check if we have a local path that needs uploading
      if (widget.isOnboarding) {
        final prefs = await SharedPreferences.getInstance();
        final localPath =
            widget.profileImage ?? prefs.getString('profile_image_path');

        if (localPath != null && !localPath.startsWith('http')) {
          debugPrint(
              '[ChatSettings] Uploading local profile image to Cloudinary: $localPath');
          try {
            final uploadResult = await cloudinary.uploadFileUnsigned(
              filePath: localPath,
            );
            finalProfilePicUrl = uploadResult.secureUrl;
            debugPrint(
                '[ChatSettings] Image uploaded successfully: $finalProfilePicUrl');
          } catch (e) {
            debugPrint('[ChatSettings] Cloudinary upload failed: $e');
            // We could either stop here or continue with local path (though local path won't work for other users)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Image upload failed: $e'),
                    backgroundColor: Colors.red),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      // Build updated chat preferences
      final updatedChatPrefs = mymodel.ChatPreferences(
        matchWithGender: _oppositeGenderOnly ? 'opposite' : null,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        onlyVerified: _verifiedUsersOnly,
        interests: _likedInterests.toList(),
        dealBreakers: _dislikedInterests.toList(),
      );

      // Update Firestore
      Map<String, dynamic> firestoreData;

      if (widget.isOnboarding) {
        // During onboarding, save all user data (profile + chat preferences)
        // since About page only saved to local prefs
        // Resolve profile details from available sources (user object, widget params, or lightweight prefs)
        String? resolvedAge = _user!.age;
        String resolvedName = _user!.fullName;
        String? resolvedGender = _user!.gender;
        String? resolvedLocation = _user!.location;
        double? resolvedLat = _user!.latitude;
        double? resolvedLng = _user!.longitude;

        if (widget.isOnboarding) {
          final profile = await mymodel.User.getProfileDetails();
          resolvedAge =
              resolvedAge ?? widget.userAge ?? profile['age']?.toString();
          resolvedName = (resolvedName.isNotEmpty)
              ? resolvedName
              : (widget.userName ?? profile['fullName'] ?? resolvedName);
          resolvedGender =
              resolvedGender ?? widget.userGender ?? profile['gender'];
          resolvedLocation = resolvedLocation ?? profile['location'];
          resolvedLat = resolvedLat ?? profile['latitude'] as double?;
          resolvedLng = resolvedLng ?? profile['longitude'] as double?;
        }

        debugPrint(
            '[ChatSettings] Resolved profile for saving: name=$resolvedName, gender=$resolvedGender, age=$resolvedAge, location=$resolvedLocation');

        firestoreData = {
          'uid': _user!.uid, // Ensure UID is included
          'email': _user!.email,
          'fullName': resolvedName,
          'gender': resolvedGender,
          'age': resolvedAge,
          'profilePicUrl': finalProfilePicUrl ?? _user!.profilePicUrl,
          'interests': _user!.interests,
          'location': resolvedLocation,
          'latitude': resolvedLat,
          'longitude': resolvedLng,
          'locationUpdatedAt': _user!.locationUpdatedAt ?? Timestamp.now(),
          'chatPreferences': updatedChatPrefs.toJson(),
          'createdAt': _user!.createdAt, // Include creation time
          'privacySettings': _user!.privacySettings?.toJson(),
        };
      } else {
        // Regular mode: only update chat preferences
        firestoreData = {
          'chatPreferences': updatedChatPrefs.toJson(),
        };
      }

      await FirestoreService().updateUser(_user!.uid, firestoreData);

      // Update local user and save to SharedPreferences
      // Ensure resolvedName, resolvedGender, and resolvedAge are defined
      String? resolvedAge = _user!.age;
      String resolvedName = _user!.fullName;
      String? resolvedGender = _user!.gender;
      String? resolvedLocation = _user!.location;
      double? resolvedLat = _user!.latitude;
      double? resolvedLng = _user!.longitude;

      if (widget.isOnboarding) {
        final profile = await mymodel.User.getProfileDetails();
        resolvedAge =
            resolvedAge ?? widget.userAge ?? profile['age']?.toString();
        resolvedName = (resolvedName.isNotEmpty)
            ? resolvedName
            : (widget.userName ?? profile['fullName'] ?? resolvedName);
        resolvedGender =
            resolvedGender ?? widget.userGender ?? profile['gender'];
        resolvedLocation = resolvedLocation ?? profile['location'];
        resolvedLat = resolvedLat ?? profile['latitude'] as double?;
        resolvedLng = resolvedLng ?? profile['longitude'] as double?;
      }

      final updatedUser = mymodel.User(
        uid: _user!.uid,
        email: _user!.email,
        fullName: resolvedName,
        createdAt: _user!.createdAt,
        profilePicUrl: finalProfilePicUrl ?? _user!.profilePicUrl,
        gender: resolvedGender,
        age: resolvedAge,
        interests: _user!.interests,
        verificationLevel: _user!.verificationLevel,
        chatPreferences: updatedChatPrefs,
        privacySettings: _user!.privacySettings,
        location: resolvedLocation,
        latitude: resolvedLat,
        longitude: resolvedLng,
        locationUpdatedAt: _user!.locationUpdatedAt ?? Timestamp.now(),
      );
      await mymodel.User.saveToPrefs(updatedUser);

      debugPrint('[ChatSettings] Preferences saved successfully');

      // Mark onboarding completed so app resumes to Home on restart
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_step', 'completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Preferences saved successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Navigate to ProfileCreated in onboarding mode, otherwise pop back
        if (widget.isOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileCreated(
                profileImage: widget.profileImage,
                name: widget.userName ?? _user!.fullName,
                gender: widget.userGender ?? _user!.gender ?? '',
                age: widget.userAge ?? _user!.age ?? '',
              ),
            ),
          );
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('[ChatSettings] Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: widget.isBottomSheet
              ? BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                )
              : null,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final content = SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Fixed header section
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20.w, widget.isBottomSheet ? 8.h : 16.h, 20.w, 0),
              child: Column(
                children: [
                  if (widget.isBottomSheet) _buildDragHandle(theme),
                  _buildHeader(theme),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
            // Scrollable options section
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
                children: [
                  _buildAgeRangeSelector(theme),
                  SizedBox(height: 28.h),
                  _buildInterestsSection(theme),
                  // Hide advanced settings in onboarding mode
                  if (!widget.isOnboarding) ...[
                    SizedBox(height: 28.h),
                    _buildPreferenceToggles(theme),
                  ],
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      // Let the parent DraggableScrollableSheet handle the drag gestures
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
            widget.isOnboarding ? 'Chat Preferences' : 'Matching Preferences'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: widget.isOnboarding
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // In onboarding mode, go back to About page instead of default pop
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EditInformation(editType: 'About'),
                    ),
                  );
                },
              )
            : null, // Use default back button for non-onboarding
      ),
      body: Stack(
        children: [
          content,
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.primaryColor),
                    SizedBox(height: 16.h),
                    Text(
                      widget.isOnboarding
                          ? 'Creating your profile...'
                          : 'Saving preferences...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    // Simple visual drag handle - the actual dragging is handled by parent DraggableScrollableSheet
    return Center(
      child: Container(
        width: 40.w,
        height: 5.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: theme.dividerColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(3.r),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Match',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              // Text(
              //   'Tap to like (max $_maxLikes), double-tap to dislike (max $_maxDislikes)',
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     color: theme.hintColor,
              //   ),
              // ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        _buildSaveButtonCompact(theme),
      ],
    );
  }

  Widget _buildSaveButtonCompact(ThemeData theme) {
    return GestureDetector(
      onTap: _isSaving ? null : _savePreferences,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSaving
                ? [theme.disabledColor, theme.disabledColor]
                : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: _isSaving
              ? null
              : [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: _isSaving
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Save',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInterestsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Vibe Check',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Counters row
        Row(
          children: [
            // Likes counter
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border:
                      Border.all(color: theme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite,
                        color: theme.primaryColor, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Likes: ${_likedInterests.length}/$_maxLikes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Dislikes counter
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.heart_broken,
                        color: Colors.red.shade400, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Dislikes: ${_dislikedInterests.length}/$_maxDislikes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Selected interests display (liked + disliked)
        if (_likedInterests.isNotEmpty || _dislikedInterests.isNotEmpty) ...[
          Text(
            'Your Selections',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                // Liked interests first (primary color)
                ..._likedInterests.map((interest) => _buildInterestChip(
                      theme,
                      interest,
                      chipState: ChipState.liked,
                    )),
                // Then disliked interests (red)
                ..._dislikedInterests.map((interest) => _buildInterestChip(
                      theme,
                      interest,
                      chipState: ChipState.disliked,
                    )),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],

        // Interest pool
        Text(
          'Interest Pool',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Tap = Like  •  Double-tap = Dislike  •  Tap selected to remove',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _interestPool.map((interest) {
            ChipState state = ChipState.neutral;
            if (_likedInterests.contains(interest)) {
              state = ChipState.liked;
            } else if (_dislikedInterests.contains(interest)) {
              state = ChipState.disliked;
            }
            return _buildInterestChip(theme, interest, chipState: state);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestChip(
    ThemeData theme,
    String interest, {
    required ChipState chipState,
  }) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (chipState) {
      case ChipState.liked:
        bgColor = theme.primaryColor;
        textColor = Colors.white;
        borderColor = theme.primaryColor;
        break;
      case ChipState.disliked:
        bgColor = Colors.red.shade400;
        textColor = Colors.white;
        borderColor = Colors.red.shade400;
        break;
      case ChipState.neutral:
        bgColor = theme.cardColor;
        textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
        borderColor = theme.dividerColor.withOpacity(0.5);
        break;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.95, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () => _handleTap(interest, chipState),
        onDoubleTap: () => _handleDoubleTap(interest, chipState),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: chipState != ChipState.neutral
                ? [
                    BoxShadow(
                      color: bgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                interest,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: chipState != ChipState.neutral
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (chipState != ChipState.neutral) ...[
                SizedBox(width: 6.w),
                Icon(
                  chipState == ChipState.liked
                      ? Icons.favorite
                      : Icons.heart_broken,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(String interest, ChipState currentState) {
    if (currentState == ChipState.liked) {
      // Remove from liked
      setState(() {
        _likedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else if (currentState == ChipState.disliked) {
      // Remove from disliked
      setState(() {
        _dislikedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else {
      // Add to liked if under limit
      if (_likedInterests.length < _maxLikes) {
        setState(() {
          _likedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        // Show dialog AFTER checking - not inside setState
        _showLimitReachedDialog('likes');
      }
    }
  }

  void _handleDoubleTap(String interest, ChipState currentState) {
    if (currentState == ChipState.disliked) {
      // Remove from disliked
      setState(() {
        _dislikedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else if (currentState == ChipState.liked) {
      // Switch from liked to disliked
      setState(() {
        _likedInterests.remove(interest);
      });
      if (_dislikedInterests.length < _maxDislikes) {
        setState(() {
          _dislikedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        _showLimitReachedDialog('dislikes');
      }
    } else {
      // Add to disliked if under limit
      if (_dislikedInterests.length < _maxDislikes) {
        setState(() {
          _dislikedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        _showLimitReachedDialog('dislikes');
      }
    }
  }

  void _showLimitReachedDialog(String type) {
    if (!mounted) return;

    // Use post frame callback to avoid navigator conflicts during gestures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final theme = Theme.of(context);
      final limit = type == 'likes' ? _maxLikes : _maxDislikes;
      final isLikes = type == 'likes';

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(
                isLikes ? Icons.favorite : Icons.heart_broken,
                color: isLikes ? theme.primaryColor : Colors.red.shade400,
              ),
              SizedBox(width: 8.w),
              Text('Limit Reached'),
            ],
          ),
          content: Text(
            'You can only select $limit $type. Please remove one before adding another.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Got it',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          ],
        ),
      );
      HapticFeedback.heavyImpact();
    });
  }

  Widget _buildAgeRangeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.cake_outlined,
                      color: Colors.white, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Age Range',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Only match with users in this age range',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
        SizedBox(height: 16.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
            thumbColor: theme.primaryColor,
            overlayColor: theme.primaryColor.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: RangeSlider(
            values: _ageRange,
            min: _minAgeLimit,
            max: _maxAgeLimit,
            divisions: (_maxAgeLimit - _minAgeLimit).round(),
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_minAgeLimit.round()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.7),
                ),
              ),
              Text(
                '${_maxAgeLimit.round()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceToggles(ThemeData theme) {
    final isLevel2 = widget.verificationLevel >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.tune, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              'Advanced Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildToggleTile(
          theme,
          title: 'Opposite Gender Only',
          subtitle: 'Only match with the opposite gender',
          value: _oppositeGenderOnly,
          isLocked: !isLevel2,
          onChanged: isLevel2
              ? (value) => setState(() => _oppositeGenderOnly = value)
              : null,
        ),
        SizedBox(height: 12.h),
        _buildToggleTile(
          theme,
          title: 'Verified Users Only',
          subtitle: 'Only match with Level 2 verified users',
          value: _verifiedUsersOnly,
          isLocked: !isLevel2,
          onChanged: isLevel2
              ? (value) => setState(() => _verifiedUsersOnly = value)
              : null,
        ),
        if (!isLevel2) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: theme.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Upgrade to Level 2 verification to unlock these settings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required bool isLocked,
    ValueChanged<bool>? onChanged,
  }) {
    return GestureDetector(
      onTap: isLocked ? () => _showLockedDialog(theme) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isLocked ? theme.cardColor.withOpacity(0.5) : theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: value && !isLocked
                ? theme.primaryColor.withOpacity(0.3)
                : theme.dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? theme.hintColor
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isLocked) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.lock_outline,
                          size: 16.sp,
                          color: theme.hintColor,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isLocked ? null : onChanged,
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: theme.primaryColor),
            SizedBox(width: 8.w),
            const Text('Level 2 Required'),
          ],
        ),
        content: const Text(
          'This feature requires Level 2 verification. Please verify your account to unlock advanced matching preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChipState { neutral, liked, disliked }
