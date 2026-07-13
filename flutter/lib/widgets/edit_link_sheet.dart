import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import 'loading_spinner.dart';
import '../theme/cool_icons.dart';

/// Bottom sheet to edit a link's title, tags and collection.
class EditLinkSheet extends StatefulWidget {
  final LinkItem link;

  const EditLinkSheet({super.key, required this.link});

  @override
  State<EditLinkSheet> createState() => _EditLinkSheetState();
}

class _EditLinkSheetState extends State<EditLinkSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _tagsController;
  String? _selectedCollectionId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.link.title);
    _tagsController = TextEditingController(text: widget.link.tags.join(', '));
    _selectedCollectionId = widget.link.collectionId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final updated = widget.link.copyWith(
      title: _titleController.text.trim().isEmpty
          ? widget.link.title
          : _titleController.text.trim(),
      tags: tags,
      collectionId: _selectedCollectionId,
      clearCollectionId: _selectedCollectionId == null,
    );

    await context.read<LinkProvider>().updateLink(updated);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final collections = context.watch<CollectionProvider>().collections;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('editLink.title'),
            style: AppFonts.body(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: t('editLink.titleLabel'),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: t('editLink.tagsLabel'),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          if (collections.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedCollectionId,
              decoration: InputDecoration(
                labelText: t('collections.fieldLabel'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(CoolIcons.folder, size: 20),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(t('collections.none')),
                ),
                ...collections.map((col) => DropdownMenuItem(
                  value: col.id,
                  child: Text(col.name),
                )),
              ],
              onChanged: (val) => setState(() => _selectedCollectionId = val),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving ? const LoadingSpinner() : const Icon(CoolIcons.save),
            label: Text(_isSaving ? t('common.saving') : t('editLink.save')),
          ),
        ],
      ),
    );
  }
}
