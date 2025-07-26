import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String initialName;
  final String initialGender;
  final int initialAge;
  final List<String> initialInterests; // Pass the current interests to edit

  const EditProfilePage({
    super.key,
    required this.initialName,
    required this.initialGender,
    required this.initialAge,
    required this.initialInterests,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String _selectedGender = 'Male'; // Default value for dropdown
  late List<String> _currentInterests; // A mutable copy to edit locally

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _ageController = TextEditingController(text: widget.initialAge.toString());

    // Set initial gender, default to 'Male' if empty or not one of the options
    if (widget.initialGender.isNotEmpty &&
        ['Male', 'Female', 'Other'].contains(widget.initialGender)) {
      _selectedGender = widget.initialGender;
    } else {
      _selectedGender = 'Male'; // Fallback
    }

    _currentInterests = List.from(widget.initialInterests); // Create a mutable copy
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- Interest Management Methods (moved from ProfileLvl1) ---
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

  void _showEditInterestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Interests'),
          content: StatefulBuilder(
            // Use StatefulBuilder to update content within dialog without rebuilding the whole page
            builder: (BuildContext context, StateSetter setStateInsideDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currentInterests.length,
                  itemBuilder: (context, index) {
                    final interest = _currentInterests[index];
                    return ListTile(
                      title: Text(interest),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Update the _currentInterests list in this page's state
                          setState(() {
                            _currentInterests.removeAt(index);
                          });
                          // Rebuild only the dialog content
                          setStateInsideDialog(() {});
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
                _showAddInterestDialog(); // Go to add interest dialog
              },
              child: const Text('Add Interest'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss edit interests dialog
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
  // --- End Interest Management Methods ---

  // Method to save changes and pop the page
  void _saveProfileChanges() {
    final String newName = _nameController.text.trim();
    final int newAge = int.tryParse(_ageController.text.trim()) ?? 0;
    final String newGender = _selectedGender;

    // Basic validation
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    if (newAge <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age')),
      );
      return;
    }

    // Return the updated data to the previous screen (ProfileLvl1)
    Navigator.pop(
      context,
      {
        'fullName': newName,
        'gender': newGender,
        'age': newAge,
        'interests': _currentInterests, // Return the updated interests list
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        titleTextStyle: theme.appBarTheme.titleTextStyle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Name',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Gender',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: <String>['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Age',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your age',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),

            // Button to edit interests
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _showEditInterestDialog, // Calls the local dialog
                child: Text(
                  'Edit Interests',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Save Changes Button
            Center(
              child: ElevatedButton(
                onPressed: _saveProfileChanges,
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
                  'Save Changes',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.scaffoldBackgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for displaying interest tags (can be reused)
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