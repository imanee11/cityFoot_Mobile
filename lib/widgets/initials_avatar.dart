import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final String? imageUrl;

  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.size,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _initialsCircle(c),
          errorWidget: (context, url, error) => _initialsCircle(c),
        ),
      );
    }
    return _initialsCircle(c);
  }

  Widget _initialsCircle(WColors c) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.circleColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: c.secondary,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
