import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'i18n.dart';

/// Standard cancel/delete confirmation dialog used everywhere a link
/// or collection is deleted. Returns true if the user confirmed.
Future<bool?> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t('common.cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            t('common.delete'),
            style: TextStyle(color: ctx.colors.statusError),
          ),
        ),
      ],
    ),
  );
}
