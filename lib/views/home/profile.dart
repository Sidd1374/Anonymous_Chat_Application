// lib/views/home/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // These variables will hold the profile data.
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
    // If the user object passed to the widget changes, re-initialize the state.
    if (widget.user != oldWidget.user) {
      _initializeStateFromWidget();
    }
  }

  // Helper method to set state from the widget's user property.
  void _initializeStateFromWidget() {
    setState(() {
      _name = widget.user.fullName;
      _gender = widget.user.gender ?? '';
      _age = int.tryParse(widget.user.age ?? '0') ?? 0;
      _profileImagePath = widget.user.profilePicUrl;
      _interests = widget.user.interests ?? [];
    });
  }

  // Helper to save interests list to SharedPreferences
  Future<void> _saveInterestsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_interests', _interests);
  }

  void _addInterest(String interest) {
    setState(() {
      _interests.add(interest);
      _saveInterestsToPrefs(); // Save changes immediately
    });
  }

  void _showAddInterestDialog() {
    final TextEditingController interestController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Interest'),
          content: TextField(
            controller: interestController,
            decoration: const InputDecoration(
              hintText: 'Enter your interest',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final interest = interestController.text.trim();
                if (interest.isNotEmpty) {
                  _addInterest(interest);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditInterestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Interests'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInsideDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _interests.length,
                  itemBuilder: (context, index) {
                    final interest = _interests[index];
                    return ListTile(
                      title: Text(interest),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _interests.removeAt(index);
                          });
                          _saveInterestsToPrefs(); // Save changes immediately
                          setStateInsideDialog(
                              () {}); // Rebuild only the dialog content
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddInterestDialog();
              },
              child: const Text('Add Interest'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditProfile() async {
    // Navigate to the edit page and wait for a result.
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditInformation(
                  editType: 'Edit Profile',
                )));

    // After returning, reload the user data from SharedPreferences to reflect any changes.
    final updatedUser = await mymodel.User.getFromPrefs();
    if (updatedUser != null) {
      setState(() {
        _name = updatedUser.fullName;
        _gender = updatedUser.gender ?? '';
        _age = int.tryParse(updatedUser.age ?? '0') ?? 0;
        _profileImagePath = updatedUser.profilePicUrl;
        _interests = updatedUser.interests ?? [];
      });
    }
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
            onPressed:
                _navigateToEditProfile,
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
                                _profileImagePath!.isNotEmpty &&
                                File(_profileImagePath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(_profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage('assets/Profile_image.png'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _name.isNotEmpty ? _name : 'Name not set',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
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