import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small inline spinner for buttons/fields in a loading state.
/// Defaults to a size and color that reads well on a filled accent
/// button; pass [color] to use it elsewhere (e.g. on a text field).
class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingSpinner({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? context.colors.accentOnPrimary,
      ),
    );
  }
}
