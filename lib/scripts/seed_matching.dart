import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Small utility to call the seedMatchingPool function.
/// You can call this from any UI button or during app startup.
Future<void> triggerSeed(BuildContext context) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('seedMatchingPool')
        .call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.data['message'] ?? 'Seeded successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Seeding failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
