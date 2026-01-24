import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';

class ProfilePage extends StatefulWidget {
  final mymodel.User? user;
  final ImageProvider? preloadedImageProvider;

  /// When viewing another user's profile, set this to true
  final bool isViewingOther;

  /// The other user's ID to fetch their profile from Firestore
  final String? otherUserId;

  /// Optional: Other user's name (fallback if Firestore fetch fails)
  final String? otherUserName;

  /// Optional: Other user's profile pic URL (fallback if Firestore fetch fails)
  final String? otherUserProfilePic;

  const ProfilePage({
    super.key,
    this.user,
    this.preloadedImageProvider,
    this.isViewingOther = false,
    this.otherUserId,
    this.otherUserName,
    this.otherUserProfilePic,
  }) : assert(user != null || (isViewingOther && otherUserId != null),
            'Either user must be provided or isViewingOther with otherUserId');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late String _name;
  late String _gender;
  late int _age;
  late String _location;
  late List<String> _interests;
  late List<String> _dislikes;
  ImageProvider? _profileImageProvider;
  bool _isLoading = true;
  int _verificationLevel = 0;
  String? _profilePicUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // For draggable sheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetExtent = 0.45; // Track current extent for fade calculations

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    if (widget.isViewingOther) {
      _loadOtherUserProfile();
    } else {
      _initializeStateFromWidget();
      _isLoading = false;
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isViewingOther && widget.user != oldWidget.user) {
      _initializeStateFromWidget();
    }
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ??
              data['fullName'] ??
              widget.otherUserName ??
              'Anonymous';
          _gender = data['gender'] ?? '';
          _age = int.tryParse(data['age']?.toString() ?? '0') ?? 0;
          _location = data['location'] ?? 'Location not set';

          // Get interests and dislikes from chatPreferences
          final chatPrefs = data['chatPreferences'] as Map<String, dynamic>?;
          _interests =
              (chatPrefs?['interests'] as List<dynamic>?)?.cast<String>() ?? [];
          _dislikes =
              (chatPrefs?['dealBreakers'] as List<dynamic>?)?.cast<String>() ??
                  [];
          _verificationLevel = data['verificationLevel'] ?? 0;
          _profilePicUrl = data['profilePicUrl'] ??
              data['profileImage'] ??
              widget.otherUserProfilePic;
          _isLoading = false;
        });

        if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
          _loadImageFromCache(_profilePicUrl!);
        }
      } else {
        setState(() {
          _name = widget.otherUserName ?? 'Anonymous';
          _gender = '';
          _age = 0;
          _location = 'Location not set';
          _interests = [];
          _dislikes = [];
          _verificationLevel = 0;
          _profilePicUrl = widget.otherUserProfilePic;
          _isLoading = false;
        });

        if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
          _loadImageFromCache(_profilePicUrl!);
        }
      }
    } catch (e) {
      debugPrint('[Profile] Error loading other user: $e');
      if (mounted) {
        setState(() {
          _name = widget.otherUserName ?? 'Anonymous';
          _gender = '';
          _age = 0;
          _location = 'Location not set';
          _interests = [];
          _dislikes = [];
          _isLoading = false;
        });
      }
    }
  }

  void _initializeStateFromWidget() {
    _name = widget.user!.fullName;
    _gender = widget.user!.gender ?? '';
    _age = int.tryParse(widget.user!.age ?? '0') ?? 0;
    _location = widget.user!.location ?? 'Location not set';
    _interests = widget.user!.chatPreferences?.interests ?? [];
    _dislikes = widget.user!.chatPreferences?.dealBreakers ?? [];
    _verificationLevel = widget.user!.verificationLevel ?? 0;
    _profilePicUrl = widget.user!.profilePicUrl;

    if (widget.preloadedImageProvider != null) {
      _profileImageProvider = widget.preloadedImageProvider;
    } else if (widget.user!.profilePicUrl != null &&
        widget.user!.profilePicUrl!.isNotEmpty) {
      _loadImageFromCache(widget.user!.profilePicUrl!);
    }
  }

  Future<void> _loadImageFromCache(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      if (mounted) {
        setState(() {
          _profileImageProvider = FileImage(file);
        });
      }
    } catch (e) {
      debugPrint('[Profile] Cache error: $e');
    }
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
    final refreshed = await mymodel.User.getFromPrefs();
    if (refreshed != null && mounted) {
      ImageProvider? newImageProvider;
      if (refreshed.profilePicUrl != null &&
          refreshed.profilePicUrl!.isNotEmpty) {
        try {
          final file = await DefaultCacheManager()
              .getSingleFile(refreshed.profilePicUrl!);
          newImageProvider = FileImage(file);
        } catch (e) {
          debugPrint('[Profile] Cache error on refresh: $e');
        }
      }

      setState(() {
        _name = refreshed.fullName;
        _gender = refreshed.gender ?? '';
        _age = int.tryParse(refreshed.age ?? '0') ?? 0;
        _location = refreshed.location ?? 'Location not set';
        _interests = refreshed.chatPreferences?.interests ?? [];
        _dislikes = refreshed.chatPreferences?.dealBreakers ?? [];
        _profileImageProvider = newImageProvider;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.isViewingOther
            ? null
            : [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  onPressed: _navigateToEditProfile,
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Profile image positioned in the top portion of the screen
            // Takes up ~65% of screen height so it's visible above the sheet
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.65,
              child: _buildProfileImage(theme),
            ),

            // Gradient overlay with name on the fade section
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: screenHeight * 0.55,
              child: _buildGradientWithName(theme),
            ),

            // Draggable bottom sheet
            DraggableScrollableSheet(
              initialChildSize: 0.42,
              minChildSize: 0.42,
              maxChildSize: 0.90,
              snap: true,
              snapSizes: const [0.42, 0.65, 0.9],
              builder: (context, scrollController) {
                return NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _sheetExtent = notification.extent;
                    });
                    return true;
                  },
                  child: _buildDraggableContent(theme, scrollController),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(ThemeData theme) {
    return GestureDetector(
      onLongPress: () => _openFullscreenImage(context),
      child: _profileImageProvider != null
          ? Image(
              image: _profileImageProvider!,
              fit: BoxFit.cover,
            )
          : _profilePicUrl != null && _profilePicUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _profilePicUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surface,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildDefaultAvatar(theme),
                )
              : _buildDefaultAvatar(theme),
    );
  }

  Widget _buildGradientWithName(ThemeData theme) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.7),
              theme.scaffoldBackgroundColor.withOpacity(0.9),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.2, 0.4, 0.6, 0.85, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableContent(
      ThemeData theme, ScrollController scrollController) {
    // Calculate content height to prevent empty space
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Name with age
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _age > 0
                        ? '${_name.isNotEmpty ? _name : 'Name not set'}, $_age'
                        : (_name.isNotEmpty ? _name : 'Name not set'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (_verificationLevel >= 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SvgPicture.asset(
                      'assets/icons/icon_verified.svg',
                      height: 28,
                      width: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Location and Gender row
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildInfoChip(
                  theme,
                  icon: Icons.location_on_outlined,
                  text: _location,
                ),
                _buildInfoChip(
                  theme,
                  icon: Icons.person_outline,
                  text: _gender.isNotEmpty ? _gender : 'Gender not set',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Interests & Dislikes Section
            if (_interests.isNotEmpty || _dislikes.isNotEmpty) ...[
              _buildInterestsDislikesSection(theme),
              const SizedBox(height: 24),
            ],

            // Verification card for own profile only
            if (!widget.isViewingOther) _buildVerificationCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.person,
          size: 120,
          color: theme.hintColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme,
      {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary.withOpacity(0.85),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsDislikesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interests Card
        if (_interests.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.primary.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Interests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_interests.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _interests
                      .map((interest) => _buildInterestTag(interest, theme))
                      .toList(),
                ),
              ],
            ),
          ),
          if (_dislikes.isNotEmpty) const SizedBox(height: 16),
        ],

        // Dislikes Card
        if (_dislikes.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400.withOpacity(0.08),
                  Colors.red.shade400.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.shade400.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.thumb_down_rounded,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Not Into',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_dislikes.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _dislikes
                      .map((dislike) => _buildDislikeTag(dislike, theme))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestTag(String interest, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            interest,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDislikeTag(String dislike, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade400.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.close_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            dislike,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(ThemeData theme) {
    final isVerified = _verificationLevel >= 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isVerified
            ? LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: isVerified
            ? null
            : Border.all(color: theme.dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isVerified
                ? Colors.green.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_user : Icons.shield_outlined,
                color: isVerified ? Colors.white : theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isVerified ? 'Verified User' : 'Basic Verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVerified
                ? 'Your identity has been verified. You have full access to all features.'
                : 'Verify your identity to get a verified badge and unlock more features.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isVerified
                  ? Colors.white.withOpacity(0.9)
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AadhaarVerification(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFullscreenImage(BuildContext context) {
    final imageUrl = _profilePicUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProfileFullscreenImageViewer(
            imageUrl: imageUrl,
            imageProvider: _profileImageProvider,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _ProfileFullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final ImageProvider? imageProvider;

  const _ProfileFullscreenImageViewer({
    required this.imageUrl,
    this.imageProvider,
  });

  @override
  State<_ProfileFullscreenImageViewer> createState() =>
      _ProfileFullscreenImageViewerState();
}

class _ProfileFullscreenImageViewerState
    extends State<_ProfileFullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: widget.imageProvider != null
                  ? Image(
                      image: widget.imageProvider!,
                      fit: BoxFit.contain,
                    )
                  : CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.error,
                        size: 64,
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
