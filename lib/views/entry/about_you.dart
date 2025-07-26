import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/views/entry/profile_created.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANT: Add this import

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
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String _selectedGender = 'Select a gender'; // Default for creation
  List<String> _currentInterests =
      []; // Initialized empty, loaded for edit mode
  bool _isLoading = true; // State to manage data loading

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();

    // Check editType and load data if in 'Edit Profile' mode
    if (widget.editType == 'P' || widget.editType == 'Edit Profile') {
      _loadExistingUserData();
    } else {
      // For 'About Me' mode, no initial data to load, so stop loading
      _isLoading = false;
      // Initialize default interests for creation mode if you have any
      _currentInterests = [
        'Gaming',
        'Music',
        'Photo / Video Editing',
        'Sports',
        'Photography',
        'Graphic Designing',
      ];
    }
  }

  // Method to load existing user data from SharedPreferences
  Future<void> _loadExistingUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final profileDetails = await mymodel.User.getProfileDetails();
    final String? savedName = profileDetails['fullName'];
    final String? savedGender = profileDetails['gender'];
    final String? savedAge = profileDetails['age'];
    final String? savedProfileImagePath = prefs.getString('profile_image_path');
    final List<String>? savedInterests = prefs.getStringList('user_interests');

    setState(() {
      _nameController.text = savedName ?? '';
      _ageController.text = savedAge ?? '';

      // Set gender, fallback to 'Select a gender' or a default option if not found
      if (savedGender != null && _genderOptions.contains(savedGender)) {
        _selectedGender = savedGender;
      } else {
        _selectedGender = 'Select a gender';
      }

      // Load profile image if path exists and file is valid
      if (savedProfileImagePath != null &&
          File(savedProfileImagePath).existsSync()) {
        _profileImage = File(savedProfileImagePath);
      } else {
        _profileImage = null; // Ensure no stale image is shown
      }

      // Load interests, default to empty list if none saved
      _currentInterests = savedInterests ?? [];

      _isLoading = false; // Data has been loaded, stop loading indicator
    });
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
      });
    }
  }

  // --- Interest Management Methods (Integrated into this page) ---
  void _addInterest(String interest) {
    setState(() {
      _currentInterests.add(interest);
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

  // ... (rest of your code) ...
// ... (Your other methods and class structure above) ...

  void _showEditInterestDialog() {
    showDialog(
      context: context,
      // The builder function for showDialog receives a BuildContext for the dialog itself.
      // We name it 'dialogContext' here to differentiate it from the context inside StatefulBuilder.
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Interests'),
          // The content of the AlertDialog is wrapped in a StatefulBuilder.
          // This builder provides a StateSetter ('setStateInsideDialog')
          // that can be used to rebuild only the content of this dialog.
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInsideDialog) {
              return SizedBox(
                width: double.maxFinite, // Dialog takes maximum available width
                // Use a Column to arrange the list of interests and the action buttons vertically.
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Allows Column to size itself to its children's height
                  children: [
                    // Flexible widget allows the ListView to take available space
                    // without causing overflow issues when used inside a Column.
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap:
                            true, // Makes ListView only take up as much space as its children
                        itemCount: _currentInterests.length,
                        itemBuilder: (context, index) {
                          final interest = _currentInterests[index];
                          return ListTile(
                            title: Text(interest),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Update the main _currentInterests list in the _EditInformationState
                                setState(() {
                                  _currentInterests.removeAt(index);
                                });
                                // Rebuild ONLY the content of this AlertDialog
                                setStateInsideDialog(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                        height: 16), // Spacing between list and buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () async {
                            // This onPressed needs to be async because it uses await
                            _showAddInterestDialog();
                          },
                          child: const Text('Add Interest'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Pop the current AlertDialog (_showEditInterestDialog)
                            setStateInsideDialog(() {});
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // IMPORTANT: The 'actions' property of AlertDialog should be REMOVED from here.
          // The buttons are now inside the 'content' for scope reasons.
          // actions: [
          //   // ... (DELETE THIS ENTIRE 'actions' BLOCK IF IT'S STILL HERE) ...
          // ],
        );
      },
    );
  }

// ... (Rest of your class code) ...

// ... (rest of your code) ...
  // --- End Interest Management Methods ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine AppBar title based on editType
    String appBarTitle =
        widget.editType == 'P' || widget.editType == 'Edit Profile'
            ? "Edit Profile"
            : "About Me";

    // Show loading indicator if data is still being fetched
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(appBarTitle, style: theme.appBarTheme.titleTextStyle),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          appBarTitle,
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
                            color: theme.primaryColor
                                .withOpacity(0.3), // Made shadow softer
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
                      // Display a default icon/image if no profile image is set
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
              // Conditionally render "Edit Interests" button
              if (widget.editType == 'P' || widget.editType == 'Edit Profile')
                Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _showEditInterestDialog,
                        child: Text(
                          'Edit Interests',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              _buildButton(
                  context,
                  widget.editType == 'P' || widget.editType == 'Edit Profile'
                      ? 'Save Changes'
                      : 'Continue'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build TextFields
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

  // Helper widget to build Dropdown for Gender
  Widget _buildDropdownField(BuildContext context, String placeholder) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedGender == 'Select a gender' &&
              !_genderOptions.contains(_selectedGender)
          ? null // If default is selected and not a valid option, make it null for hintText
          : _selectedGender,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        hintText: placeholder,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
      ),
      items: _genderOptions
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
      // Display current value in hint-like style if 'Select a gender' and not set
      // This helps when the initial value is 'Select a gender'
      hint: _selectedGender == 'Select a gender'
          ? Text(
              placeholder,
              style:
                  theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
            )
          : null,
    );
  }

  // Helper widget for the main action button
  Widget _buildButton(BuildContext context, String buttonText) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () async {
        // Validation
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your full name.')));
          return;
        }
        if (_selectedGender == 'Select a gender') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select your gender.')));
          return;
        }
        final int? age = int.tryParse(_ageController.text.trim());
        if (age == null || age <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a valid age.')));
          return;
        }
        // Only require profile image if in "About Me" mode and image is null
        if (_profileImage == null &&
            (widget.editType == 'A' || widget.editType == 'About')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please upload a profile picture.')));
          return;
        }

        // Save profile image locally and get path
        String? savedProfileImagePath;
        if (_profileImage != null) {
          savedProfileImagePath =
              await mymodel.User.saveProfileImageLocally(_profileImage!);
        }

        // Save profile details to SharedPreferences
        await mymodel.User.saveProfileDetails(
          fullName: _nameController.text.trim(),
          gender: _selectedGender,
          age: age,
        );

        // Save interests to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('user_interests', _currentInterests);

        // --- Navigation Logic based on editType ---
        if (widget.editType == 'P' || widget.editType == 'Edit Profile') {
          // Navigate back to ProfileLvl1 and pass updated data
          Navigator.pop(
            context,
            {
              'fullName': _nameController.text.trim(),
              'gender': _selectedGender,
              'age': age, // Pass as int
              'interests': _currentInterests,
              'profileImagePath': savedProfileImagePath,
            },
          );
        } else {
          // "About Me" mode: Navigate to ProfileCreated
          Navigator.pushReplacement(
            // Use pushReplacement to prevent going back to "About Me"
            context,
            MaterialPageRoute(
              builder: (context) => ProfileCreated(
                profileImage: _profileImage, // Pass File object
                name: _nameController.text.trim(),
                gender: _selectedGender,
                age: _ageController.text.trim(),
              ),
            ),
          );
        }
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
        buttonText,
        style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
