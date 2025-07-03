import 'package:flutter/material.dart';
import 'package:veil_chat_application/core/app_theme.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String gender;
  final String age;
  final String imagePath;
  final VoidCallback? onPressed;

  const UserCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.imagePath,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 180,
        height: 223,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary,
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Age
            Positioned(
              left: 20,
              top: 181,
              child: SizedBox(
                width: 140,
                child: Text(
                  age,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            // Gender
            Positioned(
              left: 20,
              top: 161,
              child: SizedBox(
                width: 140,
                child: Text(
                  gender,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color ??
                        const Color(0xFF282725),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            // Name
            Positioned(
              left: 20,
              top: 137,
              child: SizedBox(
                width: 140,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color ??
                        const Color(0xFF282725),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Profile Image
            Positioned(
              left: 40,
              top: 24,
              child: Container(
                width: 100,
                height: 100,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: imagePath.startsWith('http')
                        ? NetworkImage(imagePath)
                        : AssetImage(imagePath) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            // Placeholder for badge or icon
            Positioned(
              left: 144,
              top: 16,
              child: Container(width: 20, height: 20, child: Stack()),
            ),
          ],
        ),
      ),
    );
  }
}
