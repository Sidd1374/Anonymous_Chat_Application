import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/services/firestore_service.dart';

class ChatSettingsPage extends StatefulWidget {
  final int verificationLevel;
  final bool isBottomSheet;
  final ScrollController? scrollController;

  const ChatSettingsPage({
    super.key,
    this.verificationLevel = 0,
    this.isBottomSheet = false,
    this.scrollController,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Selected interests (liked = primary, disliked = red)
  final Set<String> _likedInterests = {};
  final Set<String> _dislikedInterests = {};

  // Max limits
  static const int _maxLikes = 5;
  static const int _maxDislikes = 5;

  // Age range
  RangeValues _ageRange = const RangeValues(18, 40);
  static const double _minAgeLimit = 18;
  static const double _maxAgeLimit = 60;

  // Toggles
  bool _oppositeGenderOnly = false;
  bool _verifiedUsersOnly = false;

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // User data
  mymodel.User? _user;

  // Hardcoded pool of interests
  static const List<String> _interestPool = [
    '🎮 Gaming',
    '🎵 Music',
    '📚 Reading',
    '🎬 Movies',
    '🏋️ Fitness',
    '🍳 Cooking',
    '✈️ Travel',
    '📷 Photography',
    '🎨 Art',
    '💻 Technology',
    '🌱 Nature',
    '🧘 Meditation',
    '🎭 Theater',
    '⚽ Sports',
    '🐕 Pets',
    '🎲 Board Games',
    '📝 Writing',
    '🎸 Instruments',
    '🌍 Languages',
    '🔬 Science',
    '🧠 Psychology',
    '💼 Business',
    '🎤 Karaoke',
    '🍿 Anime',
    '📱 Social Media',
    '🏕️ Camping',
    '🎯 Darts',
    '🧩 Puzzles',
    '🎪 Comedy',
    '👗 Fashion',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedPreferences();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final user = await mymodel.User.getFromPrefs();
      if (user != null && mounted) {
        setState(() {
          _user = user;
          if (user.chatPreferences != null) {
            _likedInterests.addAll(user.chatPreferences!.interests ?? []);
            _dislikedInterests.addAll(user.chatPreferences!.dealBreakers ?? []);
            _ageRange = RangeValues(
              (user.chatPreferences!.minAge ?? 18)
                  .toDouble()
                  .clamp(_minAgeLimit, _maxAgeLimit),
              (user.chatPreferences!.maxAge ?? 40)
                  .toDouble()
                  .clamp(_minAgeLimit, _maxAgeLimit),
            );
            _oppositeGenderOnly = user.chatPreferences!.matchWithGender != null;
            _verifiedUsersOnly = user.chatPreferences!.onlyVerified ?? false;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[ChatSettings] Error loading preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_user == null) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build updated chat preferences
      final updatedChatPrefs = mymodel.ChatPreferences(
        matchWithGender: _oppositeGenderOnly ? 'opposite' : null,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        onlyVerified: _verifiedUsersOnly,
        interests: _likedInterests.toList(),
        dealBreakers: _dislikedInterests.toList(),
      );

      // Update Firestore
      final firestoreData = {
        'chatPreferences': updatedChatPrefs.toJson(),
      };
      await FirestoreService().updateUser(_user!.uid, firestoreData);

      // Update local user and save to SharedPreferences
      final updatedUser = mymodel.User(
        uid: _user!.uid,
        email: _user!.email,
        fullName: _user!.fullName,
        createdAt: _user!.createdAt,
        profilePicUrl: _user!.profilePicUrl,
        gender: _user!.gender,
        age: _user!.age,
        interests: _user!.interests,
        verificationLevel: _user!.verificationLevel,
        chatPreferences: updatedChatPrefs,
        privacySettings: _user!.privacySettings,
        location: _user!.location,
        latitude: _user!.latitude,
        longitude: _user!.longitude,
        locationUpdatedAt: _user!.locationUpdatedAt,
      );
      await mymodel.User.saveToPrefs(updatedUser);

      debugPrint('[ChatSettings] Preferences saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Preferences saved successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('[ChatSettings] Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: widget.isBottomSheet
              ? BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                )
              : null,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final content = SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          controller: widget.scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              20.w, widget.isBottomSheet ? 8.h : 16.h, 20.w, 32.h),
          children: [
            if (widget.isBottomSheet) _buildDragHandle(theme),
            _buildHeader(theme),
            SizedBox(height: 24.h),
            _buildInterestsSection(theme),
            SizedBox(height: 28.h),
            _buildAgeRangeSelector(theme),
            SizedBox(height: 28.h),
            _buildPreferenceToggles(theme),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      // Let the parent DraggableScrollableSheet handle the drag gestures
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Matching Preferences'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: content,
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    // Simple visual drag handle - the actual dragging is handled by parent DraggableScrollableSheet
    return Center(
      child: Container(
        width: 40.w,
        height: 5.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: theme.dividerColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(3.r),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Match',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Tap to like (max $_maxLikes), double-tap to dislike (max $_maxDislikes)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        _buildSaveButtonCompact(theme),
      ],
    );
  }

  Widget _buildSaveButtonCompact(ThemeData theme) {
    return GestureDetector(
      onTap: _isSaving ? null : _savePreferences,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSaving
                ? [theme.disabledColor, theme.disabledColor]
                : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: _isSaving
              ? null
              : [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: _isSaving
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Save',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInterestsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counters row
        Row(
          children: [
            // Likes counter
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border:
                      Border.all(color: theme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite,
                        color: theme.primaryColor, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Likes: ${_likedInterests.length}/$_maxLikes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Dislikes counter
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.heart_broken,
                        color: Colors.red.shade400, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Dislikes: ${_dislikedInterests.length}/$_maxDislikes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Selected interests display (liked + disliked)
        if (_likedInterests.isNotEmpty || _dislikedInterests.isNotEmpty) ...[
          Text(
            'Your Selections',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                // Liked interests first (primary color)
                ..._likedInterests.map((interest) => _buildInterestChip(
                      theme,
                      interest,
                      chipState: ChipState.liked,
                    )),
                // Then disliked interests (red)
                ..._dislikedInterests.map((interest) => _buildInterestChip(
                      theme,
                      interest,
                      chipState: ChipState.disliked,
                    )),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],

        // Interest pool
        Text(
          'Interest Pool',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Tap = Like  •  Double-tap = Dislike  •  Tap selected to remove',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _interestPool.map((interest) {
            ChipState state = ChipState.neutral;
            if (_likedInterests.contains(interest)) {
              state = ChipState.liked;
            } else if (_dislikedInterests.contains(interest)) {
              state = ChipState.disliked;
            }
            return _buildInterestChip(theme, interest, chipState: state);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestChip(
    ThemeData theme,
    String interest, {
    required ChipState chipState,
  }) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (chipState) {
      case ChipState.liked:
        bgColor = theme.primaryColor;
        textColor = Colors.white;
        borderColor = theme.primaryColor;
        break;
      case ChipState.disliked:
        bgColor = Colors.red.shade400;
        textColor = Colors.white;
        borderColor = Colors.red.shade400;
        break;
      case ChipState.neutral:
        bgColor = theme.cardColor;
        textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
        borderColor = theme.dividerColor.withOpacity(0.5);
        break;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.95, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () => _handleTap(interest, chipState),
        onDoubleTap: () => _handleDoubleTap(interest, chipState),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: chipState != ChipState.neutral
                ? [
                    BoxShadow(
                      color: bgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                interest,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: chipState != ChipState.neutral
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (chipState != ChipState.neutral) ...[
                SizedBox(width: 6.w),
                Icon(
                  chipState == ChipState.liked
                      ? Icons.favorite
                      : Icons.heart_broken,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(String interest, ChipState currentState) {
    if (currentState == ChipState.liked) {
      // Remove from liked
      setState(() {
        _likedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else if (currentState == ChipState.disliked) {
      // Remove from disliked
      setState(() {
        _dislikedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else {
      // Add to liked if under limit
      if (_likedInterests.length < _maxLikes) {
        setState(() {
          _likedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        // Show dialog AFTER checking - not inside setState
        _showLimitReachedDialog('likes');
      }
    }
  }

  void _handleDoubleTap(String interest, ChipState currentState) {
    if (currentState == ChipState.disliked) {
      // Remove from disliked
      setState(() {
        _dislikedInterests.remove(interest);
      });
      HapticFeedback.lightImpact();
    } else if (currentState == ChipState.liked) {
      // Switch from liked to disliked
      setState(() {
        _likedInterests.remove(interest);
      });
      if (_dislikedInterests.length < _maxDislikes) {
        setState(() {
          _dislikedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        _showLimitReachedDialog('dislikes');
      }
    } else {
      // Add to disliked if under limit
      if (_dislikedInterests.length < _maxDislikes) {
        setState(() {
          _dislikedInterests.add(interest);
        });
        HapticFeedback.mediumImpact();
      } else {
        _showLimitReachedDialog('dislikes');
      }
    }
  }

  void _showLimitReachedDialog(String type) {
    if (!mounted) return;

    // Use post frame callback to avoid navigator conflicts during gestures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final theme = Theme.of(context);
      final limit = type == 'likes' ? _maxLikes : _maxDislikes;
      final isLikes = type == 'likes';

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(
                isLikes ? Icons.favorite : Icons.heart_broken,
                color: isLikes ? theme.primaryColor : Colors.red.shade400,
              ),
              SizedBox(width: 8.w),
              Text('Limit Reached'),
            ],
          ),
          content: Text(
            'You can only select $limit $type. Please remove one before adding another.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Got it',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          ],
        ),
      );
      HapticFeedback.heavyImpact();
    });
  }

  Widget _buildAgeRangeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.cake_outlined,
                    color: theme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Age Range',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Only match with users in this age range',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
        SizedBox(height: 16.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
            thumbColor: theme.primaryColor,
            overlayColor: theme.primaryColor.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: RangeSlider(
            values: _ageRange,
            min: _minAgeLimit,
            max: _maxAgeLimit,
            divisions: (_maxAgeLimit - _minAgeLimit).round(),
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_minAgeLimit.round()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.7),
                ),
              ),
              Text(
                '${_maxAgeLimit.round()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceToggles(ThemeData theme) {
    final isLevel2 = widget.verificationLevel >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: theme.primaryColor, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Advanced Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildToggleTile(
          theme,
          title: 'Opposite Gender Only',
          subtitle: 'Only match with the opposite gender',
          value: _oppositeGenderOnly,
          isLocked: !isLevel2,
          onChanged: isLevel2
              ? (value) => setState(() => _oppositeGenderOnly = value)
              : null,
        ),
        SizedBox(height: 12.h),
        _buildToggleTile(
          theme,
          title: 'Verified Users Only',
          subtitle: 'Only match with Level 2 verified users',
          value: _verifiedUsersOnly,
          isLocked: !isLevel2,
          onChanged: isLevel2
              ? (value) => setState(() => _verifiedUsersOnly = value)
              : null,
        ),
        if (!isLevel2) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: theme.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Upgrade to Level 2 verification to unlock these settings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required bool isLocked,
    ValueChanged<bool>? onChanged,
  }) {
    return GestureDetector(
      onTap: isLocked ? () => _showLockedDialog(theme) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isLocked ? theme.cardColor.withOpacity(0.5) : theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: value && !isLocked
                ? theme.primaryColor.withOpacity(0.3)
                : theme.dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isLocked
                              ? theme.hintColor
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isLocked) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.lock_outline,
                          size: 16.sp,
                          color: theme.hintColor,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isLocked ? null : onChanged,
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: theme.primaryColor),
            SizedBox(width: 8.w),
            const Text('Level 2 Required'),
          ],
        ),
        content: const Text(
          'This feature requires Level 2 verification. Please verify your account to unlock advanced matching preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChipState { neutral, liked, disliked }
