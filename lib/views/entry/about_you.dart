import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/services/firestore_service.dart';
import 'package:veil_chat_application/views/settings/chat_settings.dart';
import 'package:veil_chat_application/services/cloudinary_service.dart';
import 'package:veil_chat_application/services/profile_image_service.dart';
import 'package:veil_chat_application/services/location_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:veil_chat_application/views/entry/profile_created.dart';

class EditInformation extends StatefulWidget {
  final String editType; // Can be 'About' or 'Edit Profile'

  const EditInformation({
    super.key,
    required this.editType,
  });

  @override
  State<EditInformation> createState() => _EditInformationState();
}

class _EditInformationState extends State<EditInformation> {
  File? _profileImage;
  String? _profileImageUrl;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String _selectedGender = 'Select a gender';
  List<String> _currentInterests = [];
  bool _isLoading = true;

  // Location fields
  String? _location;
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  String? _locationError;
  final LocationService _locationService = LocationService();

  // Track if form was submitted to show validation errors
  bool _showValidationErrors = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _loadExistingUserData();
  }

  Future<void> _loadExistingUserData() async {
    final user = await mymodel.User.getFromPrefs();
    if (user != null) {
      setState(() {
        _nameController.text =
            user.fullName.isNotEmpty ? user.fullName : (_nameController.text);
        _ageController.text = (user.age != null && user.age!.isNotEmpty)
            ? user.age!
            : _ageController.text;
        _selectedGender =
            (user.gender != null && user.gender != 'Select a gender')
                ? user.gender!
                : _selectedGender;
        _currentInterests = user.interests ?? [];
        _profileImageUrl = user.profilePicUrl;
        _location = user.location ?? _location;
        _latitude = user.latitude ?? _latitude;
        _longitude = user.longitude ?? _longitude;
      });
    }

    // Always check lightweight profile details as fallback or for onboarding consistency
    final profile = await mymodel.User.getProfileDetails();
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_path');

    setState(() {
      if (_nameController.text.isEmpty)
        _nameController.text = profile['fullName'] ?? '';
      if (_ageController.text.isEmpty)
        _ageController.text = profile['age'] ?? '';
      if (_selectedGender == 'Select a gender')
        _selectedGender = profile['gender'] ?? 'Select a gender';
      if (_location == null) _location = profile['location'];
      if (_latitude == null) _latitude = profile['latitude'];
      if (_longitude == null) _longitude = profile['longitude'];

      // Fallback for profile image path
      if (_profileImage == null && _profileImageUrl == null) {
        if (savedImagePath != null && File(savedImagePath).existsSync()) {
          _profileImage = File(savedImagePath);
        }
      }
    });
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationError = null;
    });

    final result = await _locationService.detectCurrentLocation();

    if (mounted) {
      setState(() {
        _isDetectingLocation = false;
        if (result.success && result.data != null) {
          _location = result.data!.locationName;
          _latitude = result.data!.latitude;
          _longitude = result.data!.longitude;
          _locationError = null;
        } else {
          _locationError = result.errorMessage;
          // Handle specific permission issues
          if (result.permissionStatus ==
              LocationPermissionStatus.deniedForever) {
            _showLocationSettingsDialog();
          } else if (result.permissionStatus ==
              LocationPermissionStatus.serviceDisabled) {
            _showEnableLocationDialog();
          }
        }
      });
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services (GPS) to detect your location automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openLocationSettings();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _profileImageUrl = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final isEditMode = widget.editType == 'Edit Profile';

    // Validate required fields
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final hasValidGender = _genderOptions.contains(_selectedGender);
    final hasLocation = _location != null && _location!.isNotEmpty;
    final hasImage = _profileImage != null || _profileImageUrl != null;

    // For onboarding, all fields are required
    if (!isEditMode) {
      bool missingFields = false;
      String errorMessage = '';

      if (name.isEmpty) {
        missingFields = true;
        errorMessage = 'Please enter your name';
      } else if (age.isEmpty) {
        missingFields = true;
        errorMessage = 'Please enter your age';
      } else if (!hasValidGender) {
        missingFields = true;
        errorMessage = 'Please select your gender';
      } else if (!hasImage) {
        missingFields = true;
        errorMessage = 'Please select a profile image';
      } else if (!hasLocation) {
        missingFields = true;
        errorMessage = 'Please detect your location';
      }

      if (missingFields) {
        setState(() {
          _showValidationErrors = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validate age is numeric and within allowed bounds (18 - 100)
    if (age.isNotEmpty) {
      final parsedAge = int.tryParse(age);
      if (parsedAge == null || parsedAge < 18 || parsedAge > 100) {
        setState(() {
          _showValidationErrors = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid age between 18 and 100'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        // UPDATE MODE: Update Firebase
        final user = await mymodel.User.getFromPrefs();
        if (user != null) {
          // Upload new profile image if selected
          String? newImageUrl = _profileImageUrl;
          if (_profileImage != null) {
            final uploadResult = await cloudinary.uploadFileUnsigned(
              filePath: _profileImage!.path,
            );
            newImageUrl = uploadResult.secureUrl;
          }

          // Prepare update data
          final Map<String, dynamic> updateData = {
            'fullName': name,
            'age': age,
            'gender': _selectedGender,
            if (newImageUrl != null) 'profilePicUrl': newImageUrl,
            if (_location != null) 'location': _location,
            if (_latitude != null) 'latitude': _latitude,
            if (_longitude != null) 'longitude': _longitude,
            'locationUpdatedAt': Timestamp.now(),
          };

          // Update Firebase
          final firestoreService = FirestoreService();
          await firestoreService.updateUser(user.uid, updateData);

          // Update local preferences with new user data
          final updatedUser = mymodel.User(
            uid: user.uid,
            email: user.email,
            fullName: name,
            createdAt: user.createdAt,
            profilePicUrl: newImageUrl ?? user.profilePicUrl,
            gender: _selectedGender,
            age: age,
            interests: user.interests,
            verificationLevel: user.verificationLevel,
            chatPreferences: user.chatPreferences,
            privacySettings: user.privacySettings,
            location: _location ?? user.location,
            latitude: _latitude ?? user.latitude,
            longitude: _longitude ?? user.longitude,
            locationUpdatedAt: Timestamp.now(),
          );
          await mymodel.User.saveToPrefs(updatedUser);

          // Clear image cache if profile picture was updated
          if (_profileImage != null && newImageUrl != null) {
            await DefaultCacheManager().removeFile(newImageUrl);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } else {
        // ONBOARDING MODE: Save locally
        await mymodel.User.saveProfileDetails(
          fullName: name,
          gender: _selectedGender,
          age: age,
          location: _location,
          latitude: _latitude,
          longitude: _longitude,
        );

        // Verify that profile details were written to SharedPreferences
        final _prefs = await SharedPreferences.getInstance();
        debugPrint(
            '[AboutYou] Saved profile details -> fullName=${_prefs.getString('user_fullName')}, location=${_prefs.getString('user_location')}');

        // Save profile image locally if selected
        String? savedImagePath;
        if (_profileImage != null) {
          savedImagePath =
              await mymodel.User.saveProfileImageLocally(_profileImage!);
          debugPrint('[AboutYou] Saved profile image locally: $savedImagePath');
        }

        debugPrint(
            '[AboutYou] Onboarding save complete -> location=$_location');

        if (mounted) {
          // Mark onboarding progress so app can resume in the right step
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('onboarding_step', 'preferences');

          // Navigate to next step in onboarding (interests page)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatSettingsPage(
                isOnboarding: true,
                profileImage: savedImagePath,
                userName: name,
                userGender: _selectedGender,
                userAge: age.toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditMode = widget.editType == 'Edit Profile';
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: theme.primaryColor)),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Gradient Background Header
            Container(
              height: screenHeight * 0.32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          theme.primaryColor.withOpacity(0.3),
                          theme.scaffoldBackgroundColor
                        ]
                      : [
                          theme.primaryColor.withOpacity(0.15),
                          theme.scaffoldBackgroundColor
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Back Button Row
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: theme.cardColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  Icon(Icons.arrow_back_ios_new, size: 18.sp),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Title Section (on top)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        Text(
                          isEditMode
                              ? 'Edit Your Profile'
                              : 'Create Your Profile',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          isEditMode
                              ? 'Update your information'
                              : 'Let\'s get to know you',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Avatar Section (below title)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.2),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardColor,
                            image: _getProfileImage(),
                          ),
                          child: (_profileImage == null &&
                                  _profileImageUrl == null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded,
                                        size: 28.sp,
                                        color: theme.primaryColor
                                            .withOpacity(0.6)),
                                    SizedBox(height: 4.h),
                                    Text('ADD PHOTO',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryColor
                                              .withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        )),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: EdgeInsets.all(6.w),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: theme.cardColor, width: 2),
                                        ),
                                        child: Icon(Icons.edit,
                                            size: 12.sp, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Form Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name Input
                        _buildElegantInput(
                          theme: theme,
                          label: 'YOUR NAME',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: 20.h),

                        // Gender & Age Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildElegantDropdown(theme),
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              flex: 3,
                              child: _buildElegantInput(
                                theme: theme,
                                label: 'AGE',
                                hint: '18+',
                                controller: _ageController,
                                icon: Icons.cake_outlined,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Location
                        _buildElegantLocation(theme, isEditMode),

                        SizedBox(height: 24.h),

                        // Submit Button
                        _buildFloatingButton(theme, isEditMode),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    if (_profileImage != null) {
      return DecorationImage(
          image: FileImage(_profileImage!), fit: BoxFit.cover);
    } else if (_profileImageUrl != null) {
      return DecorationImage(
          image: CachedNetworkImageProvider(_profileImageUrl!),
          fit: BoxFit.cover);
    }
    return null;
  }

  Widget _buildElegantInput({
    required ThemeData theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(icon, size: 20.sp, color: theme.primaryColor),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    isNumber ? TextInputType.number : TextInputType.text,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.6)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 8.h),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.5),
                theme.primaryColor.withOpacity(0.1)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantDropdown(ThemeData theme) {
    final hasValue = _genderOptions.contains(_selectedGender);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasValue
                  ? theme.primaryColor.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: hasValue ? _selectedGender : null,
              hint: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 18.sp, color: theme.hintColor),
                  SizedBox(width: 8.w),
                  Text('Select', style: TextStyle(color: theme.hintColor)),
                ],
              ),
              isExpanded: true,
              isDense: true,
              icon: const SizedBox(),
              dropdownColor: theme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
              selectedItemBuilder: (context) {
                return _genderOptions.map((g) {
                  return Row(
                    children: [
                      Icon(
                        g == 'Male'
                            ? Icons.male_rounded
                            : (g == 'Female'
                                ? Icons.female_rounded
                                : Icons.transgender_rounded),
                        size: 18.sp,
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(g,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  );
                }).toList();
              },
              items: _genderOptions.map((g) {
                final isSelected = g == _selectedGender;
                return DropdownMenuItem(
                  value: g,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor.withOpacity(0.15)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            g == 'Male'
                                ? Icons.male_rounded
                                : (g == 'Female'
                                    ? Icons.female_rounded
                                    : Icons.transgender_rounded),
                            size: 18.sp,
                            color: isSelected
                                ? theme.primaryColor
                                : theme.hintColor,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          g,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.primaryColor : null,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              size: 18.sp, color: theme.primaryColor),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedGender = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantLocation(ThemeData theme, bool isEditMode) {
    final hasLocation = _location != null && _location!.isNotEmpty;
    final hasError = _showValidationErrors && !isEditMode && !hasLocation;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: hasLocation
            ? Colors.green.withOpacity(0.08)
            : (hasError
                ? Colors.red.withOpacity(0.08)
                : theme.scaffoldBackgroundColor),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasLocation
              ? Colors.green.withOpacity(0.3)
              : (hasError ? Colors.red.withOpacity(0.3) : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: hasLocation
                  ? Colors.green.withOpacity(0.15)
                  : theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation ? Icons.check_rounded : Icons.location_on_rounded,
              size: 22.sp,
              color: hasLocation
                  ? Colors.green
                  : (hasError ? Colors.red : theme.primaryColor),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation ? 'Location Detected' : 'Your Location',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: hasLocation
                        ? Colors.green
                        : (hasError ? Colors.red : theme.primaryColor),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  hasLocation ? _location! : 'Required to match nearby',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasLocation
                        ? theme.textTheme.bodyLarge?.color
                        : theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isDetectingLocation ? null : _detectLocation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: _isDetectingLocation
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      hasLocation ? 'Refresh' : 'Detect',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(ThemeData theme, bool isEditMode) {
    return GestureDetector(
      onTap: _handleSubmit,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEditMode ? 'Save Changes' : 'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEditMode ? Icons.check : Icons.arrow_forward,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Avatar with gradient ring
  Widget _buildHeroAvatar(ThemeData theme) {
    final hasImage = _profileImage != null || _profileImageUrl != null;
    final hasError = _showValidationErrors && !hasImage;

    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: hasError
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [theme.primaryColor, theme.primaryColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!), fit: BoxFit.cover)
                    : (_profileImageUrl != null &&
                            _profileImageUrl!.startsWith('http'))
                        ? DecorationImage(
                            image:
                                CachedNetworkImageProvider(_profileImageUrl!),
                            fit: BoxFit.cover)
                        : (_profileImageUrl != null &&
                                File(_profileImageUrl!).existsSync())
                            ? DecorationImage(
                                image: FileImage(File(_profileImageUrl!)),
                                fit: BoxFit.cover)
                            : null,
              ),
              child: !hasImage
                  ? Icon(Icons.person_rounded,
                      size: 48.sp, color: theme.hintColor.withOpacity(0.5))
                  : null,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color:
                  (hasError ? Colors.red : theme.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasImage ? Icons.edit_rounded : Icons.add_a_photo_rounded,
                  size: 16.sp,
                  color: hasError ? Colors.red : theme.primaryColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  hasImage ? 'Change Photo' : 'Add Photo',
                  style: TextStyle(
                    color: hasError ? Colors.red : theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium Form Field
  Widget _buildPremiumField(
      ThemeData theme, String label, IconData icon, Widget child) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: theme.primaryColor),
              SizedBox(width: 6.w),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  // Premium Location Field
  Widget _buildPremiumLocationField(ThemeData theme) {
    final isEditMode = widget.editType == 'Edit Profile';
    final hasLocation = _location != null && _location!.isNotEmpty;
    final hasError = _locationError != null ||
        (_showValidationErrors && !isEditMode && !hasLocation);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: hasError
                ? Colors.red.withOpacity(0.4)
                : theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (hasLocation
                      ? Colors.green
                      : (hasError ? Colors.red : theme.primaryColor))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              hasLocation
                  ? Icons.check_circle_rounded
                  : Icons.location_on_rounded,
              size: 22.sp,
              color: hasLocation
                  ? Colors.green
                  : (hasError ? Colors.red : theme.primaryColor),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError ? Colors.red : theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  hasLocation
                      ? _location!
                      : (_locationError ?? 'Tap to detect your location'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasError
                        ? Colors.red
                        : (hasLocation ? null : theme.hintColor),
                    fontWeight:
                        hasLocation ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isDetectingLocation ? null : _detectLocation,
            style: TextButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: _isDetectingLocation
                ? SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          hasLocation
                              ? Icons.refresh_rounded
                              : Icons.my_location_rounded,
                          size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(hasLocation ? 'Refresh' : 'Detect'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Gradient Button
  Widget _buildGradientButton(ThemeData theme) {
    final isEditMode = widget.editType == 'Edit Profile';
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Trigger validation and save
            _buildButton(context, '');
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditMode ? 'Save Changes' : 'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  isEditMode
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact profile row with photo on left and text on right
  Widget _buildCompactProfileRow(ThemeData theme) {
    final hasImage = _profileImage != null || _profileImageUrl != null;
    final hasError = _showValidationErrors && !hasImage;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasError ? Colors.red : theme.primaryColor,
                  width: 2,
                ),
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!), fit: BoxFit.cover)
                    : _profileImageUrl != null
                        ? DecorationImage(
                            image:
                                CachedNetworkImageProvider(_profileImageUrl!),
                            fit: BoxFit.cover)
                        : null,
                color: theme.scaffoldBackgroundColor,
              ),
              child: !hasImage
                  ? Icon(Icons.person, size: 32.sp, color: theme.hintColor)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage ? 'Profile Photo' : 'Add Profile Photo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasError ? Colors.red : null,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasImage ? 'Tap to change' : 'Required',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasError ? Colors.red.shade300 : theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.edit : Icons.camera_alt,
              color: hasError ? Colors.red : theme.primaryColor,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  // Compact inline field with icon and label
  Widget _buildInlineField(
      ThemeData theme, IconData icon, String label, Widget child) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: theme.primaryColor),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 11.sp,
                ),
              ),
              child,
            ],
          ),
        ),
      ],
    );
  }

  // Compact location field
  Widget _buildCompactLocation(ThemeData theme) {
    final isEditMode = widget.editType == 'Edit Profile';
    final hasError = _locationError != null ||
        (_showValidationErrors &&
            !isEditMode &&
            (_location == null || _location!.isEmpty));
    final hasLocation = _location != null && _location!.isNotEmpty;

    return Row(
      children: [
        Icon(
          hasLocation ? Icons.check_circle : Icons.location_on,
          size: 18.sp,
          color: hasLocation
              ? Colors.green
              : (hasError ? Colors.red : theme.primaryColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Location${!isEditMode ? ' *' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasError ? Colors.red : theme.hintColor,
                  fontSize: 11.sp,
                ),
              ),
              Text(
                hasLocation ? _location! : 'Tap detect to get location',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasLocation ? null : theme.hintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _isDetectingLocation ? null : _detectLocation,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isDetectingLocation
              ? SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(hasLocation ? 'Refresh' : 'Detect',
                  style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
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
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(width: 8.w),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme) {
    final hasImage = _profileImage != null || _profileImageUrl != null;
    final hasError = _showValidationErrors && !hasImage;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : LinearGradient(
                      colors: [
                        theme.cardColor,
                        theme.cardColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: hasError
                      ? Colors.red.withOpacity(0.3)
                      : theme.primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Profile Image Container
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasError ? Colors.red : theme.primaryColor,
                      width: 3.w,
                    ),
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : _profileImageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                    _profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: !hasImage
                      ? Icon(
                          Icons.person_outline,
                          size: 60.sp,
                          color:
                              hasError ? Colors.red.shade300 : theme.hintColor,
                        )
                      : null,
                ),
                // Camera/Add Button
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasError ? Colors.red : theme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (hasError ? Colors.red : theme.primaryColor)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      hasImage ? Icons.edit : Icons.camera_alt,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          hasImage ? "Tap to change photo" : "Add a profile photo",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasError ? Colors.red : theme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '⚠ Profile picture is required',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalDetailsCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernInputField(
            theme,
            label: 'Full Name',
            hint: 'Enter your name',
            icon: Icons.badge_outlined,
            controller: _nameController,
          ),
          SizedBox(height: 16.h),
          _buildModernDropdownField(theme),
          SizedBox(height: 16.h),
          _buildModernInputField(
            theme,
            label: 'Age',
            hint: 'Enter your age',
            icon: Icons.cake_outlined,
            controller: _ageController,
            numeric: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputField(
    ThemeData theme, {
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool numeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.sp, color: theme.primaryColor),
            SizedBox(width: 8.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdownField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wc_outlined, size: 18.sp, color: theme.primaryColor),
            SizedBox(width: 8.w),
            Text(
              'Gender',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          ),
          child: DropdownButtonFormField<String>(
            value: _genderOptions.contains(_selectedGender)
                ? _selectedGender
                : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              hintText: 'Select gender',
              hintStyle:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            dropdownColor: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            items: _genderOptions
                .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender, style: theme.textTheme.bodyLarge)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGender = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    final hasLocationError = (_locationError != null ||
        (_showValidationErrors &&
            widget.editType != 'Edit Profile' &&
            (_location == null || _location!.isEmpty)));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: hasLocationError
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: hasLocationError
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_location != null && _location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _location!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Tap to detect your location',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              hasLocationError ? Colors.red : theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: _isDetectingLocation ? null : _detectLocation,
                icon: _isDetectingLocation
                    ? SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.my_location, size: 18.sp),
                label: Text(_isDetectingLocation ? 'Detecting...' : 'Detect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          if (_locationError != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String buttonText) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: () async {
        // Check for profile image first
        if (_profileImage == null && _profileImageUrl == null) {
          setState(() {
            _showValidationErrors = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload a profile picture.')),
          );
          return;
        }

        if (_nameController.text.trim().isEmpty ||
            _selectedGender == 'Select a gender' ||
            _ageController.text.trim().isEmpty) {
          setState(() {
            _showValidationErrors = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill all fields.')));
          return;
        }

        // Check for location in About mode (mandatory during registration)
        if (widget.editType != 'Edit Profile' &&
            (_location == null || _location!.isEmpty)) {
          setState(() {
            _showValidationErrors = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please detect your location to continue.')));
          return;
        }

        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()));

        try {
          final user = await mymodel.User.getFromPrefs();
          if (user == null) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('User not found. Please log in again.')));
            return;
          }

          final trimmedInterests = _currentInterests
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();
          final currentPic = user.profilePicUrl;
          final targetPicChanged = _profileImage != null;
          final newFullName = _nameController.text.trim();
          final newGender = _selectedGender;
          final newAge = _ageController.text.trim();

          final hasChanges = newFullName != user.fullName ||
              newGender != (user.gender ?? '') ||
              newAge != (user.age ?? '') ||
              targetPicChanged ||
              _location != user.location ||
              _latitude != user.latitude ||
              _longitude != user.longitude ||
              !_listEqualsIgnoreOrder(trimmedInterests, user.interests ?? []);

          if (!hasChanges) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No changes to save')));
            return;
          }

          String? profilePicUrl = currentPic;

          if (targetPicChanged) {
            // Unsigned upload to Cloudinary in Profiles/<uid>/Avatar_<timestamp>.jpg
            final publicId =
                'Avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final uploadResult = await cloudinary.uploadFileUnsigned(
              filePath: _profileImage!.path,
              folder: 'Profiles/${user.uid}',
              publicId: publicId,
            );
            profilePicUrl = uploadResult.secureUrl;

            // Warm cache so the profile image appears quickly
            final downloadResult =
                await DefaultCacheManager().downloadFile(profilePicUrl);
            ProfileImageService().updateImageProvider(
              FileImage(downloadResult.file),
              url: profilePicUrl,
              file: downloadResult.file,
            );
          }

          // Only update Firebase for Edit Profile mode
          // During registration (About mode), we save to local prefs only
          // Firebase update will happen after Chat Settings page during onboarding
          if (widget.editType == 'Edit Profile') {
            final updatedDataForFirebase = {
              'fullName': newFullName,
              'gender': newGender,
              'age': newAge,
              'profilePicUrl': profilePicUrl,
              'interests': trimmedInterests,
              'location': _location,
              'latitude': _latitude,
              'longitude': _longitude,
              'locationUpdatedAt': _location != null ? Timestamp.now() : null,
            };
            await FirestoreService()
                .updateUser(user.uid, updatedDataForFirebase);
          }

          final updatedUserForPrefs = mymodel.User(
            uid: user.uid,
            email: user.email,
            createdAt: user.createdAt,
            fullName: newFullName,
            gender: newGender,
            age: newAge,
            interests: trimmedInterests,
            profilePicUrl: profilePicUrl,
            chatPreferences: user.chatPreferences,
            privacySettings: user.privacySettings,
            verificationLevel: user.verificationLevel,
            location: _location,
            latitude: _latitude,
            longitude: _longitude,
            locationUpdatedAt: _location != null ? Timestamp.now() : null,
          );

          await mymodel.User.saveToPrefs(updatedUserForPrefs);

          Navigator.of(context, rootNavigator: true).pop();

          if (widget.editType == 'Edit Profile') {
            Navigator.pop(context);
          } else {
            // Navigate to ChatSettingsPage for onboarding instead of ProfileCreated
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatSettingsPage(
                  isOnboarding: true,
                  profileImage: updatedUserForPrefs.profilePicUrl,
                  userName: updatedUserForPrefs.fullName,
                  userGender: updatedUserForPrefs.gender ?? '',
                  userAge: updatedUserForPrefs.age ?? '',
                ),
              ),
            );
          }
        } catch (e) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save changes: $e')));
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(182.w, 50.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: theme.primaryColor,
        shadowColor: theme.primaryColor,
        elevation: 5,
      ),
      child: Text(buttonText,
          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
    );
  }
}

bool _listEqualsIgnoreOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  final sb = b.toSet();
  if (sa.length != sb.length) return false;
  return sa.containsAll(sb);
}
