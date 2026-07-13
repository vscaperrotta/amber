import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';

/// Deterministic palette used to color-code a link by its domain —
/// same domain always gets the same color, across avatar and stripe.
const kLinkAccentColors = [
  Color(0xFF7C6FE8), // purple
  Color(0xFF4CAF7D), // green
  Color(0xFFD98C3B), // amber-brown
  Color(0xFF5096F0), // blue
  Color(0xFFEE5555), // red
  Color(0xFF4ECDC4), // teal
  Color(0xFFF06292), // pink
  Color(0xFFA78BFA), // violet
];

Color linkAccentColor(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = 0x1fffffff & (hash + unit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= (hash >> 6);
  }
  return kLinkAccentColors[hash % kLinkAccentColors.length];
}

/// Rounded-square avatar for a link: shows its thumbnail image when
/// available, otherwise a colored square with the domain's first letter.
/// Color and letter are both derived from [domain], so the same source
/// always renders the same way.
class LinkAvatar extends StatelessWidget {
  final String domain;
  final String? imageUrl;
  final double size;

  const LinkAvatar({
    super.key,
    required this.domain,
    this.imageUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 4);
    final color = linkAccentColor(domain);
    final letter = domain.isNotEmpty ? domain[0].toUpperCase() : '?';

    final fallback = Container(
      width: size,
      height: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppFonts.body(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? fallback
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
