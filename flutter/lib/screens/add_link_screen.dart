import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/link_provider.dart';
import '../providers/collection_provider.dart';
import '../services/metadata_service.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';

class AddLinkScreen extends StatefulWidget {
  final String? initialUrl;

  const AddLinkScreen({super.key, this.initialUrl});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _tagsFocusNode = FocusNode();
  bool _isSaving = false;
  bool _isFetchingTitle = false;
  List<String> _tagSuggestions = [];
  String? _thumbnail;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _urlFocusNode.addListener(_onUrlFocusChanged);
    _tagsFocusNode.addListener(_onTagsFocusChanged);
    _tagsController.addListener(_onTagsChanged);

    // Se l'URL è pre-compilato (share intent), fetch automatico del titolo
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTitle());
    }
  }

  @override
  void dispose() {
    _urlFocusNode.removeListener(_onUrlFocusChanged);
    _tagsFocusNode.removeListener(_onTagsFocusChanged);
    _tagsController.removeListener(_onTagsChanged);
    _urlFocusNode.dispose();
    _tagsFocusNode.dispose();
    _urlController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onUrlFocusChanged() {
    if (!_urlFocusNode.hasFocus) {
      _fetchTitle();
    }
  }

  void _onTagsFocusChanged() {
    if (!_tagsFocusNode.hasFocus) {
      setState(() => _tagSuggestions = []);
    }
  }

  void _onTagsChanged() {
    final text = _tagsController.text;
    final tokens = text.split(',');
    final currentToken = tokens.last.trim().toUpperCase();

    if (currentToken.isEmpty) {
      setState(() => _tagSuggestions = []);
      return;
    }

    // Tag già inseriti nei token precedenti (da non ri-suggerire)
    final alreadyAdded = tokens
        .take(tokens.length - 1)
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toSet();

    final allTags = context.read<LinkProvider>().allTags;
    final suggestions = allTags
        .where(
          (tag) =>
              tag.startsWith(currentToken) &&
              tag != currentToken &&
              !alreadyAdded.contains(tag),
        )
        .toList();

    setState(() => _tagSuggestions = suggestions);
  }

  void _selectSuggestion(String tag) {
    final text = _tagsController.text;
    final tokens = text.split(',');
    // Sostituisce l'ultimo token con il tag selezionato
    tokens[tokens.length - 1] = ' $tag';
    final newText = '${tokens.join(',')}, ';
    _tagsController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _tagSuggestions = []);
  }

  Future<void> _fetchTitle() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !_isValidUrl(url)) return;
    if (_titleController.text.trim().isNotEmpty) return;

    setState(() => _isFetchingTitle = true);
    final meta = await MetadataService.fetchMetadata(url);
    if (mounted) {
      if (meta.title != null && _titleController.text.trim().isEmpty) {
        _titleController.text = meta.title!;
      }
      _thumbnail = meta.thumbnail;
      setState(() => _isFetchingTitle = false);
    }
  }

  bool _isValidUrl(String url) {
    final withScheme = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    return Uri.tryParse(withScheme)?.hasAbsolutePath ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final url = _urlController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? url
        : _titleController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Capture provider before popping — context invalid after Navigator.pop
    final provider = context.read<LinkProvider>();

    final result = await provider.addLink(
      url: url,
      title: title,
      tags: tags,
      thumbnail: _thumbnail,
      collectionId: _selectedCollectionId,
    );

    if (result.isDuplicate) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('addLink.duplicateError'))),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('addLink.title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                decoration: InputDecoration(
                  labelText: t('addLink.urlLabel'),
                  hintText: t('addLink.urlHint'),
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autofocus: widget.initialUrl == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t('addLink.urlRequired');
                  }
                  if (!_isValidUrl(value.trim())) {
                    return t('addLink.urlInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: t('addLink.titleLabel'),
                  hintText: t('addLink.titleHint'),
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isFetchingTitle
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.accent,
                            ),
                          ),
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                focusNode: _tagsFocusNode,
                decoration: InputDecoration(
                  labelText: t('addLink.tagsLabel'),
                  hintText: t('addLink.tagsHint'),
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              if (_tagSuggestions.isNotEmpty)
                Material(
                  elevation: 4,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _tagSuggestions.length,
                      itemBuilder: (context, index) {
                        final tag = _tagSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.label_outline, size: 18),
                          title: Text(tag),
                          onTap: () => _selectSuggestion(tag),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Consumer<CollectionProvider>(
                builder: (context, collectionProvider, _) {
                  final collections = collectionProvider.collections;
                  if (collections.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String>(
                    value: _selectedCollectionId,
                    decoration: InputDecoration(
                      labelText: t('collections.fieldLabel'),
                      prefixIcon: const Icon(Icons.folder_outlined),
                      border: const OutlineInputBorder(),
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
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.accentOnPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? t('common.saving') : t('common.save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
