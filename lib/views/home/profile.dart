import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/app_theme.dart';
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';

class ProfileLvl1 extends StatefulWidget {
  const ProfileLvl1({super.key});

  @override
  _ProfileLvl1State createState() => _ProfileLvl1State();
}

class _ProfileLvl1State extends State<ProfileLvl1> {
  final List<String> _interests = [
    'Gaming',
    'Music',
    'Photo / Video Editing',
    'Sports',
    'Photography',
    'Graphic Designing',
  ];

  void _addInterest(String interest) {
    setState(() {
      _interests.add(interest);
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Add navigation to settings page
              Navigator.pushNamed(context, '/settings');
            },
          ),
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
                    // Profile Picture
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/Profile_image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // User Information
                    Text(
                      'John Doe',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Male',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Age: 28',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 30),
                    // Interests Section
                    Wrap(
                      alignment:
                          WrapAlignment.center, // Align interests in the center
                      spacing: 10,
                      runSpacing: 10,
                      children: _interests
                          .map((interest) => _buildInterestTag(interest, theme))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    // Add Interests Button
                    TextButton(
                      onPressed: _showAddInterestDialog,
                      child: Text(
                        'Add Interests',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
                        // Add navigation or verification logic here
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

  // Helper method to build interest tags
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
