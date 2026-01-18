
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/views/entry/aadhaar_verification.dart';
import 'package:veil_chat_application/views/entry/about_you.dart';

class ProfileLvl1 extends StatefulWidget {
  final mymodel.User user;
  final ImageProvider? preloadedImageProvider;
  
  const ProfileLvl1({
    super.key,
    required this.user,
    this.preloadedImageProvider,
  });

  @override
  _ProfileLvl1State createState() => _ProfileLvl1State();
}

class _ProfileLvl1State extends State<ProfileLvl1> {
  late String _name;
  late String _gender;
  late int _age;
  late List<String> _interests;
  ImageProvider? _profileImageProvider;

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
    _name = widget.user.fullName;
    _gender = widget.user.gender ?? '';
    _age = int.tryParse(widget.user.age ?? '0') ?? 0;
    _interests = widget.user.interests ?? [];
    
    // Use preloaded image if available, otherwise load from cache
    if (widget.preloadedImageProvider != null) {
      _profileImageProvider = widget.preloadedImageProvider;
    } else if (widget.user.profilePicUrl != null && widget.user.profilePicUrl!.isNotEmpty) {
      _loadImageFromCache(widget.user.profilePicUrl!);
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
    // Reload latest data from SharedPreferences after edits
    final refreshed = await mymodel.User.getFromPrefs();
    if (refreshed != null && mounted) {
      // Load image from cache if URL changed or exists
      ImageProvider? newImageProvider;
      if (refreshed.profilePicUrl != null && refreshed.profilePicUrl!.isNotEmpty) {
        try {
          final file = await DefaultCacheManager().getSingleFile(refreshed.profilePicUrl!);
          newImageProvider = FileImage(file);
        } catch (e) {
          debugPrint('[Profile] Cache error on refresh: $e');
        }
      }
      
      setState(() {
        _name = refreshed.fullName;
        _gender = refreshed.gender ?? '';
        _age = int.tryParse(refreshed.age ?? '0') ?? 0;
        _interests = refreshed.interests ?? [];
        _profileImageProvider = newImageProvider;
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
                    GestureDetector(
                      onLongPress: () => _openFullscreenImage(context),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                          image: _profileImageProvider != null
                              ? DecorationImage(
                                  image: _profileImageProvider!,
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/Profile_image.png'),
                                  fit: BoxFit.cover,
                                ),
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit),
                      label: Text(
                        'Edit profile',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.scaffoldBackgroundColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                      ),
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

  void _openFullscreenImage(BuildContext context) {
    final imageUrl = widget.user.profilePicUrl;
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
  State<_ProfileFullscreenImageViewer> createState() => _ProfileFullscreenImageViewerState();
}

class _ProfileFullscreenImageViewerState extends State<_ProfileFullscreenImageViewer> {
  final TransformationController _transformationController = TransformationController();

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
          // Dismiss on tap background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          // Image with zoom
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
          // Top bar with close button
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
                    _buildIconButton(
                      context,
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
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

  Widget _buildIconButton(BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
