import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../theme/cool_icons.dart';
import '../widgets/action_sheet.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';
import 'dialogs.dart';

/// Collection (folder) CRUD dialogs — shared by the Home filter sheet and
/// the Options "Gestisci cartelle" screen so both drive the same provider
/// calls through the same prompts instead of maintaining two copies.

void showAddCollectionDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('collections.addTitle')),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: t('collections.nameHint')),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            ctx.read<CollectionProvider>().addCollection(val.trim());
            Navigator.pop(ctx);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(t('common.cancel')),
        ),
        TextButton(
          onPressed: () {
            final val = controller.text.trim();
            if (val.isNotEmpty) {
              ctx.read<CollectionProvider>().addCollection(val);
              Navigator.pop(ctx);
            }
          },
          child: Text(t('collections.add')),
        ),
      ],
    ),
  );
}

void showCollectionOptionsSheet(BuildContext context, CollectionItem collection) {
  showActionSheet(
    context,
    items: [
      ActionSheetItem(
        icon: CoolIcons.edit,
        label: t('collections.rename'),
        onTap: () => _showRenameDialog(context, collection),
      ),
      ActionSheetItem(
        icon: CoolIcons.deleteOutline,
        label: t('common.delete'),
        color: context.colors.statusError,
        onTap: () => _confirmAndDelete(context, collection),
      ),
    ],
  );
}

void _showRenameDialog(BuildContext context, CollectionItem collection) {
  final controller = TextEditingController(text: collection.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('collections.rename')),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: t('collections.nameHint')),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            ctx
                .read<CollectionProvider>()
                .renameCollection(collection.id, val.trim());
            Navigator.pop(ctx);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(t('common.cancel')),
        ),
        TextButton(
          onPressed: () {
            final val = controller.text.trim();
            if (val.isNotEmpty) {
              ctx
                  .read<CollectionProvider>()
                  .renameCollection(collection.id, val);
              Navigator.pop(ctx);
            }
          },
          child: Text(t('common.save')),
        ),
      ],
    ),
  );
}

Future<void> _confirmAndDelete(
    BuildContext context, CollectionItem collection) async {
  final confirmed = await confirmDelete(
    context,
    title: t('collections.deleteConfirm'),
    message: t('collections.deleteMessage'),
  );
  if (confirmed == true && context.mounted) {
    context.read<CollectionProvider>().deleteCollection(collection.id);
  }
}
