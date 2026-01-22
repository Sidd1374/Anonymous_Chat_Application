import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:veil_chat_application/widgets/button.dart';
import 'package:veil_chat_application/views/settings/chat_settings.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'searching_Loader.dart';
import '../entry/about_you.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  int _verificationLevel = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await mymodel.User.getFromPrefs();
    if (user != null && mounted) {
      setState(() {
        _verificationLevel = user.verificationLevel ?? 0;
      });
    }
  }

  void _initAnimations() {
    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide animation for Lottie
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for buttons
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));

    // Start animations with staggered delays
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _showMatchingPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.0, // Allow dragging all the way down to close
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.0, 0.5, 0.85, 0.95],
        builder: (context, scrollController) {
          return ChatSettingsPage(
            verificationLevel: _verificationLevel,
            isBottomSheet: true,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated text
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "Ready For Some Anonymous Fun ?",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            // Animated Lottie
            FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                  child: Lottie.asset('assets/animation/ani-1.json'),
                ),
              ),
            
            // Animated buttons
            ScaleTransition(
              scale: _buttonScaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    AppButton(
                      isPrimary: true,
                      isEnabled: true,
                      onPressed: () => {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                const LoaderScreen(),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 400),
                          ),
                        )
                      },
                      text: "Let's Go",
                    ),
                    const SizedBox(height: 16),
                    // Matching Preferences Button
                    OutlinedButton(
                      onPressed: () => _showMatchingPreferences(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        side: BorderSide(
                          color: theme.dividerColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 20,
                            color:
                                theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Matching Preferences',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
