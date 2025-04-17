import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

import '../home/container.dart';
import 'aadhaar_verification.dart';
// import '../home/home_test.dart';

class ProfileCreated extends StatelessWidget {
  final File? profileImage;
  final String name;
  final String gender;
  final String age;

  const ProfileCreated({
    super.key,
    required this.profileImage,
    required this.name,
    required this.gender,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // title: const Text('About You'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SizedBox(height: 80.h),
            _buildTitleSection(theme),
            SizedBox(height: 20.h),
            _buildProfileCard(theme),
            SizedBox(height: 150.h),
            _buildInfoText(theme),
            SizedBox(height: 30.h),
            _buildButtons(theme, context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'About You',
          style: theme.textTheme.displayLarge
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 28.h),
        ),
        SizedBox(height: 10.h),
        Text(
          'Here’s your shiny new profile.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Center(
      child: SizedBox(
        width: 380.w,
        height: 170.h,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x19000000),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2.w, color: theme.primaryColor),
                  color: theme.dialogBackgroundColor,
                ),
                child: profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          profileImage!,
                          fit: BoxFit.cover,
                          width: 100.w,
                          height: 100.h,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50.w,
                        color: theme.hintColor,
                      ),
              ),
              SizedBox(width: 16.w),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      gender,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      age,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(ThemeData theme) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'To verify your account and get it to ',
            style: theme.textTheme.bodyMedium,
          ),
          TextSpan(
            text: 'Level 2',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: ' (and get a ',
            style: theme.textTheme.bodyMedium,
          ),
          TextSpan(
            text: 'Verified Badge',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '), click on ',
            style: theme.textTheme.bodyMedium,
          ),
          TextSpan(
            text: 'Verify Now',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text:
                ' below. If you feel like you’re good to go for now, click on ',
            style: theme.textTheme.bodyMedium,
          ),
          TextSpan(
            text: 'Skip for now.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButtons(ThemeData theme, BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle verify action
            // Navigator.push(context,
            //     MaterialPageRoute(builder: (context) => LevelTwoPage()));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AadhaarVerification()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
          ),
          child: const Text('Verify'),
        ),
        SizedBox(height: 20.h),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePageFrame()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
          ),
          child: Text(
            'Skip for now',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
