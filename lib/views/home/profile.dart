
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';

class ProfileLvl1 extends StatefulWidget {
  final mymodel.User user;
  const ProfileLvl1({super.key, required this.user});

  @override
  _ProfileLvl1State createState() => _ProfileLvl1State();
}

class _ProfileLvl1State extends State<ProfileLvl1> {
  late String _name;
  late String _gender;
  late int _age;
  late String? _profileImagePath;
  late List<String> _interests;

  @override
  void initState() {
    super.initState();
    _initializeStateFromWidget();
  }

  @override
  void didUpdateWidget(ProfileLvl1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      _initializeStateFromWidget();
    }
  }

  void _initializeStateFromWidget() {
    setState(() {
      _name = widget.user.fullName;
      _gender = widget.user.gender ?? '';
      _age = int.tryParse(widget.user.age ?? '0') ?? 0;
      _profileImagePath = widget.user.profilePicUrl;
      _interests = widget.user.interests ?? [];
    });
  }

  Future<void> _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInformation(
          editType: 'Edit Profile',
        ),
      ),
    );
    // After returning from the edit page, we don't need to do anything here
    // because the SettingsPage will handle refreshing the data.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        titleTextStyle: theme.appBarTheme.titleTextStyle,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 392,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                        image: _profileImagePath != null &&
                                _profileImagePath!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_profileImagePath!),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage('assets/Profile_image.png'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _name.isNotEmpty ? _name : 'Name not set',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.user.verificationLevel == 2)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SvgPicture.asset(
                              'assets/icons/icon_verified.svg',
                              height: 24,
                              width: 24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _gender.isNotEmpty ? _gender : 'Gender not set',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _age > 0 ? 'Age: $_age' : 'Age not set',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: _interests
                          .map((interest) => _buildInterestTag(interest, theme))
                          .toList(),
                    ),
                    const SizedBox(height: 30),
                    _buildVerificationSection(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection(ThemeData theme) {
    if (widget.user.verificationLevel == 2) {
      return Column(
        children: [
          Text(
            'Level 2: Verified',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You are a Level 2 verified user!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Level 1: Basic',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We are going with your word here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'To get to Level 2 and obtain a Verified Badge:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AadhaarVerification(),
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Verify Now',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.scaffoldBackgroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInterestTag(String interest, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        interest,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.scaffoldBackgroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
