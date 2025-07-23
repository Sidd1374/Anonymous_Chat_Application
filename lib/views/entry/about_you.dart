import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/entry/profile_created.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;

// import '../home/home_test.dart';

class AboutYou extends StatefulWidget {
  const AboutYou({super.key});

  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> {
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Select a gender';
  final TextEditingController _ageController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "About Me",
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
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
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 3.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor,
                            blurRadius: 7.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 80.sp,
                              color: theme.hintColor,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: theme.primaryColor,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text("Upload Your Profile Picture"),
              SizedBox(height: 20.h),
              SizedBox(
                height: 60.h,
                child: _buildInputField(context, 'Full Name',
                    controller: _nameController),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: _buildDropdownField(context, 'Gender'),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: _buildInputField(context, 'Current Age',
                    numeric: true, controller: _ageController),
              ),
              SizedBox(height: 20.h),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Filling this information gives you a ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextSpan(
                      text: 'Level 1',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' Verification \nThis means we are going solely with your word here',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              _buildButton(context, 'Continue'),
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
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String placeholder) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      // value: _selectedGender,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        hintText: placeholder,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
      ),
      items: ['Male', 'Female', 'Other']
          .map(
            (gender) => DropdownMenuItem(
              value: gender,
              child: Text(
                gender,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value!;
        });
      },
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () async {
        // Save name, gender, and age to SharedPreferences
        await mymodel.User.saveProfileDetails(
          fullName: _nameController.text.isNotEmpty
              ? _nameController.text
              : 'John Doe',
          gender:
              _selectedGender != 'Select a gender' ? _selectedGender : 'Male',
          age: _ageController.text.isNotEmpty ? _ageController.text : '20',
        );

        // Save profile image locally and store path in SharedPreferences
        String? imagePath;
        if (_profileImage != null) {
          imagePath =
              await mymodel.User.saveProfileImageLocally(_profileImage!);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileCreated(
              profileImage: _profileImage,
              name: _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'John Doe',
              gender: _selectedGender != 'Select a gender'
                  ? _selectedGender
                  : 'Male',
              age: _ageController.text.isNotEmpty ? _ageController.text : '20',
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(182.w, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        backgroundColor: theme.primaryColor,
        shadowColor: theme.primaryColor,
        elevation: 5,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
