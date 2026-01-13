
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/services/firestore_service.dart';
import 'package:veil_chat_application/views/entry/profile_created.dart';
import 'package:veil_chat_application/services/cloudinary_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final TextEditingController _interestController = TextEditingController();

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
        _nameController.text = user.fullName;
        _ageController.text = user.age ?? '';
        _selectedGender = user.gender ?? 'Select a gender';
        _currentInterests = user.interests ?? [];
        _profileImageUrl = user.profilePicUrl;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _interestController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String appBarTitle = widget.editType == 'Edit Profile' ? "Edit Profile" : "About Me";

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(appBarTitle, style: theme.appBarTheme.titleTextStyle),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 150.w,
                      height: 150.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                        border: Border.all(color: theme.primaryColor, width: 3.w),
                        image: _profileImage != null
                            ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                            : _profileImageUrl != null
                                ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: _profileImage == null && _profileImageUrl == null
                          ? Icon(Icons.person, size: 80.sp, color: theme.hintColor)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: theme.primaryColor,
                      child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text("Upload Your Profile Picture"),
              SizedBox(height: 20.h),
              _buildInputField(context, 'Full Name', controller: _nameController),
              SizedBox(height: 8.h),
              _buildDropdownField(context, 'Gender'),
              SizedBox(height: 8.h),
              _buildInputField(context, 'Current Age', numeric: true, controller: _ageController),
              SizedBox(height: 16.h),
              _buildInterestsEditor(theme),
              SizedBox(height: 40.h),
              _buildButton(context, widget.editType == 'Edit Profile' ? 'Save Changes' : 'Continue'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String placeholder,
      {bool numeric = false, TextEditingController? controller}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color),
    );
  }

  Widget _buildDropdownField(BuildContext context, String placeholder) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _genderOptions.contains(_selectedGender) ? _selectedGender : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        hintText: placeholder,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
      ),
      items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender, style: theme.textTheme.bodyLarge)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedGender = value;
          });
        }
      },
    );
  }

  Widget _buildInterestsEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interests', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _interestController,
          decoration: InputDecoration(
            hintText: 'Add an interest and tap +',
            filled: true,
            fillColor: theme.cardColor,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addInterest,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
          ),
          onSubmitted: (_) => _addInterest(),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentInterests
              .map(
                (item) => Chip(
                  label: Text(item),
                  onDeleted: () {
                    setState(() {
                      _currentInterests.remove(item);
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _addInterest() {
    final v = _interestController.text.trim();
    if (v.isEmpty) return;
    if (!_currentInterests.contains(v)) {
      setState(() {
        _currentInterests.add(v);
      });
    }
    _interestController.clear();
  }

  Widget _buildButton(BuildContext context, String buttonText) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: () async {
        if (_nameController.text.trim().isEmpty || _selectedGender == 'Select a gender' || _ageController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
          return;
        }

        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

        try {
          final user = await mymodel.User.getFromPrefs();
          if (user == null) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found. Please log in again.')));
            return;
          }

          final trimmedInterests = _currentInterests.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
          final currentPic = user.profilePicUrl;
          final targetPicChanged = _profileImage != null;
          final newFullName = _nameController.text.trim();
          final newGender = _selectedGender;
          final newAge = _ageController.text.trim();

          final hasChanges =
              newFullName != user.fullName ||
              newGender != (user.gender ?? '') ||
              newAge != (user.age ?? '') ||
              targetPicChanged ||
              !_listEqualsIgnoreOrder(trimmedInterests, user.interests ?? []);

          if (!hasChanges) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes to save')));
            return;
          }

          String? profilePicUrl = currentPic;
          if (targetPicChanged) {
            // Unsigned upload to Cloudinary in Profiles/<uid>/Avatar_<timestamp>.jpg
            final publicId = 'Avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final uploadResult = await cloudinary.uploadFileUnsigned(
              filePath: _profileImage!.path,
              folder: 'Profiles/${user.uid}',
              publicId: publicId,
            );
            profilePicUrl = uploadResult.secureUrl;
            // Warm cache so the profile image appears quickly next load.
            await DefaultCacheManager().downloadFile(profilePicUrl);
          }

          final updatedDataForFirebase = {
            'fullName': newFullName,
            'gender': newGender,
            'age': newAge,
            'profilePicUrl': profilePicUrl,
            'interests': trimmedInterests,
          };

          await FirestoreService().updateUser(user.uid, updatedDataForFirebase);

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
          );

          await mymodel.User.saveToPrefs(updatedUserForPrefs);

          Navigator.of(context, rootNavigator: true).pop();

          if (widget.editType == 'Edit Profile') {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileCreated(
                  profileImage: updatedUserForPrefs.profilePicUrl,
                  name: updatedUserForPrefs.fullName,
                  gender: updatedUserForPrefs.gender ?? '',
                  age: updatedUserForPrefs.age ?? '',
                ),
              ),
            );
          }
        } catch (e) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(182.w, 50.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: theme.primaryColor,
        shadowColor: theme.primaryColor,
        elevation: 5,
      ),
      child: Text(buttonText, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
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