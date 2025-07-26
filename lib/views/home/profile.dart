// lib/views/home/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';
// Import the new EditProfilePage
import 'package:veil_chat_application/views/home/edit_profile_page.dart'; // <--- ADD THIS LINE

class ProfileLvl1 extends StatefulWidget {
  const ProfileLvl1({super.key});

  @override
  _ProfileLvl1State createState() => _ProfileLvl1State();
}

class _ProfileLvl1State extends State<ProfileLvl1> {
  // Make _interests mutable as it will be updated from EditProfilePage
  List<String> _interests = [
    'Gaming',
    'Music',
    'Photo / Video Editing',
    'Sports',
    'Photography',
    'Graphic Designing',
  ];

  String _name = '';
  String _gender = '';
  int _age = 0;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve basic profile details
    final profileDetails = await mymodel.User.getProfileDetails();
    setState(() {
      _name = profileDetails['fullName'] ?? '';
      _gender = profileDetails['gender'] ?? '';
      _age = int.tryParse(profileDetails['age'] ?? '0') ?? 0;
      _profileImagePath = prefs.getString('profile_image_path');

      // Load interests from SharedPreferences if saved. Assuming 'user_interests' key
      final savedInterests = prefs.getStringList('user_interests');
      if (savedInterests != null) {
        _interests = savedInterests;
      }
    });
  }

  // Helper to save interests list to SharedPreferences
  Future<void> _saveInterestsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_interests', _interests);
  }

  // NOTE: The _addInterest and _showAddInterestDialog methods are primarily
  // for the EditProfilePage now. If you still want to allow adding interests
  // directly from ProfileLvl1 (e.g., if you re-add the "Edit Interests" button here),
  // you can keep them. For a clean flow, the intention is to edit interests
  // via the EditProfilePage. So, I'll keep them here for now just in case.

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
    // This logic is mostly duplicated in EditProfilePage.
    // Consider if this button should still exist on ProfileLvl1 or if editing is exclusively via EditProfilePage.
    // If it stays, it directly modifies _interests and saves.
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

  // Future<void> _editProfileImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     final savedPath =
  //         await mymodel.User.saveProfileImageLocally(File(pickedFile.path));
  //     setState(() {
  //       _profileImagePath = savedPath;
  //     });
  //   }
  // }

  // --- New: Function to navigate to EditProfilePage and handle returned data ---
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditInformation(
                  editType: 'Edit Profile',
                ))
        // MaterialPageRoute(
        //   builder: (context) => EditProfilePage(
        //     initialName: _name,
        //     initialGender: _gender,
        //     initialAge: _age,
        //     initialInterests: List.from(_interests), // Pass a copy of the list
        //   ),
        // ),
        );

    // If data was returned from EditProfilePage (i.e., user saved changes)
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _name = result['fullName'] as String;
        _gender = result['gender'] as String;
        _age = result['age'] as int;
        // Update interests if they were changed
        if (result.containsKey('interests') && result['interests'] is List) {
          _interests = List<String>.from(result['interests']);
          _saveInterestsToPrefs(); // Save updated interests to prefs
        }
      });
      // Also save basic profile details to SharedPreferences
      await mymodel.User.saveProfileDetails(
        fullName: _name,
        gender: _gender,
        age: _age.toString(), // Convert int back to string for saving
      );
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
        // Add an Edit button to the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                _navigateToEditProfile, // Call the new navigation function
          ),
          const SizedBox(width: 8), // Add a little spacing if needed
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                // Consider making this width responsive, e.g., using MediaQuery.of(context).size.width * 0.9
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
                    // Profile Picture with Edit Button (Plus Icon)
                    // Stack(
                    //   alignment: Alignment.bottomRight,
                    //   children: [
                    //     Container(
                    //       width: 150,
                    //       height: 150,
                    //       decoration: BoxDecoration(
                    //         shape: BoxShape.circle,
                    //         border: Border.all(
                    //           color: theme.primaryColor,
                    //           width: 2,
                    //         ),
                    //         image: _profileImagePath != null &&
                    //                 _profileImagePath!.isNotEmpty &&
                    //                 File(_profileImagePath!).existsSync()
                    //             ? DecorationImage(
                    //                 image: FileImage(File(_profileImagePath!)),
                    //                 fit: BoxFit.cover,
                    //               )
                    //             : const DecorationImage(
                    //                 image: AssetImage('assets/Profile_image.png'),
                    //                 fit: BoxFit.cover,
                    //               ),
                    //       ),
                    //     ),
                    //     GestureDetector(
                    //       onTap: _editProfileImage,
                    //       child: CircleAvatar(
                    //         radius: 22,
                    //         backgroundColor: theme.primaryColor,
                    //         child: const Icon(
                    //           Icons.add,
                    //           color: Colors.white,
                    //           size: 24,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 20),
                    // User Information
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
                    // Interests Section
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: _interests
                          .map((interest) => _buildInterestTag(interest, theme))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    // The "Edit Interests" button that was here is now primarily
                    // located on the EditProfilePage for a more streamlined editing flow.
                    // If you want it here as well, ensure it just calls _showEditInterestDialog()
                    // and handles the list update.
                    const SizedBox(height: 30),
                    // Level Information
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
                    // Verify Button
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
