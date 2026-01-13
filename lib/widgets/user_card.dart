import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String gender;
  final String age;
  final String imagePath;
  final bool isLevel2Verified;
  final String? address;
  final VoidCallback? onPressed;

  const UserCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.imagePath,
    this.isLevel2Verified = false,
    this.address,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 180,
        height: 243,
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
                        ? CachedNetworkImageProvider(imagePath)
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
            // Level 2 Verification Logo (SVG) on top right
            if (isLevel2Verified)
              Positioned(
                right: 10,
                top: 10,
                child: SvgPicture.asset(
                  'assets/icons/icon_verified.svg', // Change path as needed
                  width: 25,
                  height: 25,
                ),
              ),
            // // Address (if verified)
            // if (isLevel2Verified && address != null && address!.isNotEmpty)
            //   Positioned(
            //     left: 10,
            //     bottom: 8,
            //     right: 10,
            //     child: Text(
            //       address!,
            //       textAlign: TextAlign.center,
            //       style: TextStyle(
            //         color: AppTheme.cardAddressColor(context),
            //         fontSize: 11,
            //         fontWeight: FontWeight.w400,
            //       ),
            //       maxLines: 2,
            //       overflow: TextOverflow.ellipsis,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
