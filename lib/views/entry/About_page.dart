import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../home/home_page_frame.dart';
import '../home/home_test.dart';
class About extends StatelessWidget {
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
                onTap: () {
                  // Add functionality to upload a profile picture
                  print("Profile image tapped");
                },
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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 7.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 80.sp,
                        color: theme.hintColor,
                      ),
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
                child: _buildInputField(context, 'Full Name'),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: _buildDropdownField(context, 'Gender'),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: _buildInputField(context, 'Current Age', numeric: true),
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
      {bool numeric = false}) {
    final theme = Theme.of(context);

    return TextField(
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none, // Removed border
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.textTheme.bodyLarge?.color, // Text color as per theme
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String placeholder) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none, // Removed border
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
        // Handle gender selection
      },
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () {
        // Add functionality for the continue button
        Navigator.push(context, MaterialPageRoute(builder: (Context) => HomePageFrame()));
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(182.w, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        backgroundColor: theme.primaryColor,
        shadowColor: theme.primaryColor.withOpacity(0.3),
        elevation: 5,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
