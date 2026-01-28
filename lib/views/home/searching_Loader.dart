import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:veil_chat_application/widgets/button.dart';
import 'package:veil_chat_application/services/matching_service.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/services/location_service.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoaderScreen extends StatefulWidget {
  final double buttonWidth;
  final double borderRadius;

  const LoaderScreen({
    super.key,
    this.buttonWidth = 150.0,
    this.borderRadius = 15,
  });

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
  final MatchingService _matchingService = MatchingService();
  final LocationService _locationService = LocationService();

  Timer? _timer;
  int _secondsElapsed = 0;
  final int _maxSeconds = 300; // 5 minutes

  StreamSubscription? _matchingSubscription;
  bool _isInitialised = false;
  String _statusText = 'Detecting your location...';

  @override
  void initState() {
    super.initState();
    _startMatchingProcess();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _matchingSubscription?.cancel();
    _cancelSearch();
    super.dispose();
  }

  Future<void> _cancelSearch() async {
    final user = await mymodel.User.getFromPrefs();
    if (user != null) {
      await _matchingService.cancelSearch(user.uid);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsElapsed++;
      });

      if (_secondsElapsed >= _maxSeconds) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No one found at the moment. High traffic or no matches found. Come back later for matching!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _startMatchingProcess() async {
    try {
      // 1. Get current user
      final user = await mymodel.User.getFromPrefs();
      if (user == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // 2. Enforce Location
      setState(() => _statusText = 'Verifying location...');
      final locResult = await _locationService.detectCurrentLocation();

      if (!locResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locResult.errorMessage ??
                  'Location access is required for matching.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => _locationService.openAppSettings(),
              ),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Update location in Firestore for the user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'latitude': locResult.data!.latitude,
        'longitude': locResult.data!.longitude,
        'location': locResult.data!.locationName,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Start Timer & Matching Process
      setState(() {
        _statusText = 'Scanning for compatible strangers...';
        _isInitialised = true;
      });
      _startTimer();

      _performGlobalMatching(user, locResult.data!);
    } catch (e) {
      debugPrint('Matching error: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('TimeoutException')) {
          errorMsg =
              'Location detection timed out. Please ensure you have a clear GPS signal and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _performGlobalMatching(
      mymodel.User user, LocationData loc) async {
    if (!mounted || _secondsElapsed >= _maxSeconds) return;

    String? genderPref;
    if (user.chatPreferences?.matchWithGender == 'opposite') {
      genderPref = 'opposite';
    } else if (user.chatPreferences?.matchWithGender != null) {
      genderPref = user.chatPreferences?.matchWithGender;
    }

    _matchingSubscription = _matchingService
        .joinMatchingQueue(
      userId: user.uid,
      userName: user.fullName,
      userProfilePic: user.profilePicUrl,
      userGender: user.gender,
      userAge: int.tryParse(user.age ?? '0'),
      userVerificationLevel: user.verificationLevel,
      preferredGender: genderPref,
      preferredMinAge: user.chatPreferences?.minAge,
      preferredMaxAge: user.chatPreferences?.maxAge,
      preferVerifiedOnly: user.chatPreferences?.onlyVerified,
      interests: user.chatPreferences?.interests,
      dealBreakers: user.chatPreferences?.dealBreakers,
      userLatitude: loc.latitude,
      userLongitude: loc.longitude,
    )
        .listen((result) async {
      if (!mounted) return;

      if (result.status == MatchingStatus.matched) {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatArea(
              userName: result.matchedUserName ?? 'Stranger',
              userImage: result.matchedUserProfilePic ?? '',
              chatId: result.chatRoomId!,
              otherUserId: result.matchedUserId!,
            ),
          ),
        );
      } else if (result.status == MatchingStatus.timeout) {
        // No match found in the current pool.
        // Wait 15 seconds and try again until the 5-minute timer hits.
        await Future.delayed(const Duration(seconds: 15));
        if (mounted && _secondsElapsed < _maxSeconds) {
          _matchingSubscription?.cancel();
          _performGlobalMatching(user, loc);
        }
      } else if (result.status == MatchingStatus.error) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Matching error: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset("assets/animation/ani-3.json"),
              const SizedBox(height: 20),
              Text(
                _statusText,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_isInitialised) ...[
                const SizedBox(height: 10),
                Text(
                  _formatTime(_secondsElapsed),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
              const SizedBox(height: 40),
              AppButton(
                isPrimary: true,
                isEnabled: true,
                onPressed: () => Navigator.pop(context),
                text: "Cancel",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
