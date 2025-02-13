import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../home/home_page_frame.dart';
import 'about_card_page.dart';

class LevelTwoPage extends StatelessWidget {
  final TextEditingController _aadhaarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            _buildTitle(context),
            SizedBox(height: 80.h),
            _buildInstructions(context),
            SizedBox(height: 20.h),
            _buildAadhaarInput(context),
            SizedBox(height: 120.h),
            _buildPrivacyText(context),
            SizedBox(height: 80.h),
            _buildContinueButton(context),
            SizedBox(height: 20.h),
            _buildGoBackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Verification 2.0',
      textAlign: TextAlign.center,
      style:
          theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPrivacyText(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 304.w,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  'Your AADHAAR number is used only during verification, and is never stored in the server or exposed to the developers or admins. For more details, please read our ',
              style: theme.textTheme.bodyMedium,
            ),
            TextSpan(
              text: 'Privacy Terms',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 304.w,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Enter your ',
              style: theme.textTheme.bodyMedium,
            ),
            TextSpan(
              text: 'AADHAAR',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: ' number below.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePageFrame()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        minimumSize: Size(182.w, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Text('Continue',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onPrimary)),
    );
  }

  Widget _buildGoBackButton(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        minimumSize: Size(182.w, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Text('Go back', style: theme.textTheme.titleMedium),
    );
  }

  Widget _buildAadhaarInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 324.w,
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: TextField(
        controller: _aadhaarController,
        keyboardType: TextInputType.number,
        maxLength: 14,
        decoration: InputDecoration(
          hintText: '_ _ _ _   _ _ _ _   _ _ _ _',
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          counterText: '',

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.r),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.r),
          ),
          fillColor: theme.inputDecorationTheme
              .fillColor, // Set the desired background color here
          filled: true,
        ),
        textAlign: TextAlign.center,
        onChanged: (value) {
          _aadhaarController.text = _formatAadhaarNumber(value);
          _aadhaarController.selection = TextSelection.fromPosition(
            TextPosition(offset: _aadhaarController.text.length),
          );
        },
      ),
    );
  }

  String _formatAadhaarNumber(String input) {
    input = input.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < input.length; i++) {
      if (i == 4 || i == 8) {
        formatted += ' ';
      }
      formatted += input[i];
    }
    return formatted;
  }
}
