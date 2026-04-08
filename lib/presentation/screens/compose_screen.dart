/// Crusader — Compose Screen
///
/// Rich email composer with glassmorphic design:
/// - To / Cc / Bcc fields with chip input
/// - Subject field
/// - Rich text body editor
/// - Attachment picker with file list
/// - Send button with keyboard shortcut (Ctrl+Enter)
///
/// Now wired to the compose provider for real SMTP sending.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_address.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/compose/compose_providers.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  late final quill.QuillController _quillController;
  final _bodyFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  bool _showCcBcc = false;

  /// Picked file attachments (local paths).
  final List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();

    // Sync text controllers with provider state after build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(composeProvider);
      // For new messages, initialize with signature.
      if (state.mode == ComposeMode.newMessage &&
          state.bodyPlain.isEmpty &&
          state.to.isEmpty) {
        ref.read(composeProvider.notifier).prepareNewMessage();
      }
      // Re-read state after potential prepareNewMessage.
      final updated = ref.read(composeProvider);
      if (updated.subject.isNotEmpty) {
        _subjectController.text = updated.subject;
      }
      if (updated.bodyPlain.isNotEmpty) {
        // Insert existing plain text into quill editor.
        final doc = quill.Document()..insert(0, updated.bodyPlain);
        _quillController.document = doc;
        _quillController.moveCursorToStart();
      }
      if (updated.cc.isNotEmpty) {
        _showCcBcc = true;
      }
    });

    // Keep provider in sync with body text.
    _quillController.document.changes.listen((_) {
      if (!mounted) return;
      final plainText = _quillController.document.toPlainText().trimRight();
      ref.read(composeProvider.notifier).updateBody(plainText);
      // Also update HTML for rich sending.
      try {
        final html = _quillDeltaToHtml(_quillController.document);
        ref.read(composeProvider.notifier).updateBodyHtml(html);
      } catch (_) {
        // Fallback — at least plain text is synced.
      }
    });
    _subjectController.addListener(() {
      ref.read(composeProvider.notifier).updateSubject(_subjectController.text);
    });
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _quillController.dispose();
    _bodyFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  /// Convert Quill Delta document to simple HTML for email sending.
  String _quillDeltaToHtml(quill.Document doc) {
    final buffer = StringBuffer();
    final delta = doc.toDelta();

    for (final op in delta.toList()) {
      if (op.data is! String) continue;
      final text = op.data as String;
      final attrs = op.attributes;

      if (text == '\n') {
        // Check for block-level formatting.
        if (attrs != null) {
          if (attrs.containsKey('list')) {
            // List items handled below.
          }
        }
        buffer.write('<br>');
        continue;
      }

      var formatted = _escapeHtml(text);

      if (attrs != null) {
        if (attrs.containsKey('bold')) {
          formatted = '<strong>$formatted</strong>';
        }
        if (attrs.containsKey('italic')) {
          formatted = '<em>$formatted</em>';
        }
        if (attrs.containsKey('underline')) {
          formatted = '<u>$formatted</u>';
        }
        if (attrs.containsKey('strike')) {
          formatted = '<s>$formatted</s>';
        }
        if (attrs.containsKey('code')) {
          formatted =
              '<code style="background:#2a2a2e;padding:2px 4px;border-radius:3px;">$formatted</code>';
        }
        if (attrs.containsKey('link')) {
          final href = attrs['link'];
          formatted = '<a href="$href">$formatted</a>';
        }
      }

      buffer.write(formatted);
    }

    return '<div style="font-family:Inter,sans-serif;font-size:14px;color:#e0e0e0;">${buffer.toString()}</div>';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  void _addToChip() {
    final text = _toController.text.trim();
    if (text.isNotEmpty && text.contains('@')) {
      ref
          .read(composeProvider.notifier)
          .addRecipient(EmailAddress(address: text));
      _toController.clear();
    }
  }

  void _addCcChip() {
    final text = _ccController.text.trim();
    if (text.isNotEmpty && text.contains('@')) {
      ref.read(composeProvider.notifier).addCc(EmailAddress(address: text));
      _ccController.clear();
    }
  }

  void _addBccChip() {
    final text = _bccController.text.trim();
    if (text.isNotEmpty && text.contains('@')) {
      ref.read(composeProvider.notifier).addBcc(EmailAddress(address: text));
      _bccController.clear();
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachments.addAll(result.files);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  String _humanFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ── Quill formatting helpers ──

  /// Toggle an inline format (bold, italic, underline, code).
  void _toggleFormat(quill.Attribute attribute) {
    final isActive = _quillController.getSelectionStyle().containsKey(
      attribute.key,
    );
    _quillController.formatSelection(
      isActive ? quill.Attribute.clone(attribute, null) : attribute,
    );
    _bodyFocusNode.requestFocus();
  }

  /// Toggle a block format (bullet list, ordered list).
  void _toggleBlockFormat(quill.Attribute attribute) {
    final style = _quillController.getSelectionStyle();
    final isActive =
        style.containsKey(attribute.key) &&
        style.attributes[attribute.key]?.value == attribute.value;
    _quillController.formatSelection(
      isActive ? quill.Attribute.clone(attribute, null) : attribute,
    );
    _bodyFocusNode.requestFocus();
  }

  /// Show a dialog to insert a link.
  void _showLinkDialog() {
    final linkController = TextEditingController();
    final selection = _quillController.selection;
    final selectedText = selection.isCollapsed
        ? ''
        : _quillController.document.toPlainText().substring(
            selection.start,
            selection.end,
          );

    // Check if selection already has a link.
    final attrs = _quillController.getSelectionStyle();
    if (attrs.containsKey('link')) {
      linkController.text = attrs.attributes['link']!.value ?? '';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CrusaderBlacks.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: CrusaderGrays.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        title: Text(
          'Insert Link',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: CrusaderGrays.primary),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        'Text: ',
                        style: TextStyle(
                          color: CrusaderGrays.muted,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          selectedText,
                          style: TextStyle(
                            color: CrusaderGrays.primary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: linkController,
                autofocus: true,
                style: TextStyle(color: CrusaderGrays.primary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: TextStyle(color: CrusaderGrays.subtle),
                  filled: true,
                  fillColor: CrusaderBlacks.charcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CrusaderGrays.border.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CrusaderGrays.border.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CrusaderAccents.cyan.withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (url) {
                  if (url.isNotEmpty) {
                    _quillController.formatSelection(quill.LinkAttribute(url));
                  }
                  Navigator.of(ctx).pop();
                  _bodyFocusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Remove link if exists.
              _quillController.formatSelection(
                quill.Attribute.clone(quill.Attribute.link, null),
              );
              Navigator.of(ctx).pop();
              _bodyFocusNode.requestFocus();
            },
            child: Text('Remove', style: TextStyle(color: CrusaderGrays.muted)),
          ),
          TextButton(
            onPressed: () {
              final url = linkController.text.trim();
              if (url.isNotEmpty) {
                _quillController.formatSelection(quill.LinkAttribute(url));
              }
              Navigator.of(ctx).pop();
              _bodyFocusNode.requestFocus();
            },
            child: Text('Apply', style: TextStyle(color: CrusaderAccents.cyan)),
          ),
        ],
      ),
    ).then((_) => linkController.dispose());
  }

  Future<void> _handleSend() async {
    // Add any text still in input fields.
    _addToChip();
    _addCcChip();
    _addBccChip();

    final notifier = ref.read(composeProvider.notifier);
    final delay = ref.read(sendDelayProvider);

    if (delay == 0) {
      // Immediate send — no undo.
      final success = await notifier.send();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email sent'),
            backgroundColor: CrusaderAccents.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        context.go('/');
      }
      return;
    }

    // Delayed send with undo — show countdown SnackBar.
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CrusaderAccents.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sending in ${delay}s...',
              style: const TextStyle(
                color: CrusaderGrays.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: delay + 1),
        backgroundColor: CrusaderBlacks.elevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: CrusaderGrays.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: CrusaderAccents.cyan,
          onPressed: () {
            notifier.cancelSend();
          },
        ),
      ),
    );

    final success = await notifier.scheduleSend();
    if (success && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email sent'),
          backgroundColor: CrusaderAccents.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(composeProvider);
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    // Show error snackbar when error state changes.
    ref.listen<ComposeState>(composeProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: CrusaderAccents.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _handleSend,
        // Quill handles Ctrl+B/I/U natively — no need to wire manually.
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header bar ──
                      _buildHeader(composeState, accents, textTheme),
                      const SizedBox(height: 16),

                      // ── Main compose card ──
                      Expanded(
                        child: _buildComposeCard(
                          composeState,
                          accents,
                          textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ComposeState composeState,
    CrusaderAccentTheme accents,
    TextTheme textTheme,
  ) {
    return Row(
          children: [
            // Discard button
            _ComposeAction(
              icon: Icons.close_rounded,
              tooltip: 'Discard (Esc)',
              onPressed: () {
                ref.read(composeProvider.notifier).reset();
                context.go('/');
              },
            ),
            const SizedBox(width: 12),
            // Title
            Text(
              _headerTitle(composeState.mode),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Attachment button
            _ComposeAction(
              icon: Icons.attach_file_rounded,
              tooltip: 'Attach files',
              onPressed: _pickAttachments,
              badgeCount: _attachments.length,
            ),
            const SizedBox(width: 14),
            // Send button
            _SendButton(
              accents: accents,
              textTheme: textTheme,
              isSending: composeState.isSending || composeState.isSendPending,
              canSend: composeState.canSend,
              onSend: _handleSend,
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.04, end: 0, duration: 300.ms);
  }

  Widget _buildComposeCard(
    ComposeState composeState,
    CrusaderAccentTheme accents,
    TextTheme textTheme,
  ) {
    return Container(
          decoration: BoxDecoration(
            color: CrusaderBlacks.elevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: CrusaderGrays.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Recipient + Subject fields ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    // From field — shows active account
                    _buildFromField(accents, textTheme),
                    _fieldDivider(),

                    // To field
                    _ChipInputField(
                      label: 'To',
                      controller: _toController,
                      chips: composeState.to.map((a) => a.shortLabel).toList(),
                      onSubmit: _addToChip,
                      onRemoveChip: (i) =>
                          ref.read(composeProvider.notifier).removeRecipient(i),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => _showCcBcc = !_showCcBcc),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _showCcBcc ? 'Hide' : 'Cc/Bcc',
                          style: textTheme.labelSmall?.copyWith(
                            color: accents.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    if (_showCcBcc) ...[
                      _fieldDivider(),
                      _ChipInputField(
                        label: 'Cc',
                        controller: _ccController,
                        chips: composeState.cc
                            .map((a) => a.shortLabel)
                            .toList(),
                        onSubmit: _addCcChip,
                        onRemoveChip: (i) =>
                            ref.read(composeProvider.notifier).removeCc(i),
                      ),
                      _fieldDivider(),
                      _ChipInputField(
                        label: 'Bcc',
                        controller: _bccController,
                        chips: composeState.bcc
                            .map((a) => a.shortLabel)
                            .toList(),
                        onSubmit: _addBccChip,
                        onRemoveChip: (i) =>
                            ref.read(composeProvider.notifier).removeBcc(i),
                      ),
                    ],

                    _fieldDivider(),

                    // Subject field
                    _buildSubjectField(textTheme),
                  ],
                ),
              ),

              // Divider between header fields and body
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: CrusaderGrays.border.withValues(alpha: 0.25),
              ),

              // ── Body editor (rich text) ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: quill.QuillEditor(
                    controller: _quillController,
                    focusNode: _bodyFocusNode,
                    scrollController: _editorScrollController,
                    config: quill.QuillEditorConfig(
                      placeholder: 'Write your message...',
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                          textTheme.bodyMedium!.copyWith(
                            height: 1.7,
                            color: CrusaderGrays.primary,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        placeHolder: quill.DefaultTextBlockStyle(
                          textTheme.bodyMedium!.copyWith(
                            height: 1.7,
                            color: CrusaderGrays.subtle,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        bold: textTheme.bodyMedium!.copyWith(
                          height: 1.7,
                          color: CrusaderGrays.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        italic: textTheme.bodyMedium!.copyWith(
                          height: 1.7,
                          color: CrusaderGrays.primary,
                          fontStyle: FontStyle.italic,
                        ),
                        underline: textTheme.bodyMedium!.copyWith(
                          height: 1.7,
                          color: CrusaderGrays.primary,
                          decoration: TextDecoration.underline,
                        ),
                        strikeThrough: textTheme.bodyMedium!.copyWith(
                          height: 1.7,
                          color: CrusaderGrays.primary,
                          decoration: TextDecoration.lineThrough,
                        ),
                        link: textTheme.bodyMedium!.copyWith(
                          height: 1.7,
                          color: CrusaderAccents.cyan,
                          decoration: TextDecoration.underline,
                          decorationColor: CrusaderAccents.cyan.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        inlineCode: quill.InlineCodeStyle(
                          style: textTheme.bodySmall!.copyWith(
                            color: CrusaderAccents.cyan,
                            fontFamily: 'monospace',
                            backgroundColor: CrusaderGrays.border.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        lists: quill.DefaultListBlockStyle(
                          textTheme.bodyMedium!.copyWith(
                            height: 1.7,
                            color: CrusaderGrays.primary,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(2, 2),
                          const quill.VerticalSpacing(0, 0),
                          null,
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Attachments list ──
              if (_attachments.isNotEmpty)
                _buildAttachmentList(accents, textTheme),

              // ── Bottom toolbar ──
              _buildBottomBar(accents, textTheme),

              // Error display
              if (composeState.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    composeState.error!,
                    style: textTheme.labelSmall?.copyWith(
                      color: CrusaderAccents.red,
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 80.ms)
        .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 80.ms);
  }

  Widget _fieldDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 68),
      color: CrusaderGrays.border.withValues(alpha: 0.2),
    );
  }

  Widget _buildSubjectField(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              'Subject',
              style: textTheme.bodySmall?.copyWith(
                color: CrusaderGrays.muted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _subjectController,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: CrusaderGrays.primary,
              ),
              decoration: InputDecoration(
                hintText: 'Add a subject',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: CrusaderGrays.subtle,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromField(CrusaderAccentTheme accents, TextTheme textTheme) {
    final accountState = ref.watch(accountProvider);
    final activeAccount = accountState.activeAccount;
    final accounts = accountState.accounts;
    final hasMultiple = accounts.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              'From',
              style: textTheme.bodySmall?.copyWith(
                color: CrusaderGrays.muted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          if (activeAccount != null) ...[
            // Account email
            Expanded(
              child: hasMultiple
                  ? PopupMenuButton<String>(
                      offset: const Offset(0, 36),
                      color: CrusaderBlacks.elevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: CrusaderGrays.border.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      onSelected: (accountId) {
                        ref
                            .read(accountProvider.notifier)
                            .switchAccount(accountId);
                      },
                      itemBuilder: (context) => accounts.map((account) {
                        final isActive = account.id == activeAccount.id;
                        return PopupMenuItem<String>(
                          value: account.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: isActive
                                    ? accents.primary
                                    : CrusaderGrays.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  account.email,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isActive
                                        ? accents.primary
                                        : CrusaderGrays.primary,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: accents.primary,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeAccount.email,
                            style: textTheme.bodyMedium?.copyWith(
                              color: CrusaderGrays.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 14,
                            color: CrusaderGrays.muted,
                          ),
                        ],
                      ),
                    )
                  : Text(
                      activeAccount.email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: CrusaderGrays.primary,
                      ),
                    ),
            ),
          ] else
            Expanded(
              child: Text(
                'No account',
                style: textTheme.bodyMedium?.copyWith(
                  color: CrusaderGrays.subtle,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentList(
    CrusaderAccentTheme accents,
    TextTheme textTheme,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: CrusaderGrays.border.withValues(alpha: 0.15),
        border: Border.all(
          color: CrusaderGrays.border.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 13,
                color: CrusaderGrays.muted,
              ),
              const SizedBox(width: 6),
              Text(
                '${_attachments.length} file${_attachments.length == 1 ? '' : 's'} attached',
                style: textTheme.labelSmall?.copyWith(
                  color: CrusaderGrays.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _pickAttachments,
                child: Text(
                  'Add more',
                  style: textTheme.labelSmall?.copyWith(
                    color: accents.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _attachments.asMap().entries.map((entry) {
              final file = entry.value;
              return _AttachmentChip(
                filename: file.name,
                size: _humanFileSize(file.size),
                icon: _fileIcon(file.extension),
                onRemove: () => _removeAttachment(entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _buildBottomBar(CrusaderAccentTheme accents, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CrusaderGrays.border.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Formatting buttons — Quill rich text
          _ToolbarButton(
            icon: Icons.format_bold_rounded,
            tooltip: 'Bold (Ctrl+B)',
            onPressed: () => _toggleFormat(quill.Attribute.bold),
          ),
          _ToolbarButton(
            icon: Icons.format_italic_rounded,
            tooltip: 'Italic (Ctrl+I)',
            onPressed: () => _toggleFormat(quill.Attribute.italic),
          ),
          _ToolbarButton(
            icon: Icons.format_underlined_rounded,
            tooltip: 'Underline (Ctrl+U)',
            onPressed: () => _toggleFormat(quill.Attribute.underline),
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Bullet list',
            onPressed: () => _toggleBlockFormat(quill.Attribute.ul),
          ),
          _ToolbarButton(
            icon: Icons.format_list_numbered_rounded,
            tooltip: 'Numbered list',
            onPressed: () => _toggleBlockFormat(quill.Attribute.ol),
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.link_rounded,
            tooltip: 'Insert link',
            onPressed: _showLinkDialog,
          ),
          _ToolbarButton(
            icon: Icons.code_rounded,
            tooltip: 'Inline code',
            onPressed: () => _toggleFormat(quill.Attribute.inlineCode),
          ),
          const Spacer(),
          // Attachment shortcut in toolbar
          _ToolbarButton(
            icon: Icons.attach_file_rounded,
            tooltip: 'Attach files',
            onPressed: _pickAttachments,
          ),
        ],
      ),
    );
  }

  String _headerTitle(ComposeMode mode) {
    switch (mode) {
      case ComposeMode.newMessage:
        return 'New Message';
      case ComposeMode.reply:
        return 'Reply';
      case ComposeMode.replyAll:
        return 'Reply All';
      case ComposeMode.forward:
        return 'Forward';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attachment Chip — shows a picked file with remove button
// ─────────────────────────────────────────────────────────────────────────────

class _AttachmentChip extends StatefulWidget {
  const _AttachmentChip({
    required this.filename,
    required this.size,
    required this.icon,
    required this.onRemove,
  });

  final String filename;
  final String size;
  final IconData icon;
  final VoidCallback onRemove;

  @override
  State<_AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<_AttachmentChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isHovered
              ? CrusaderGrays.border.withValues(alpha: 0.4)
              : CrusaderGrays.border.withValues(alpha: 0.2),
          border: Border.all(
            color: _isHovered
                ? accents.primary.withValues(alpha: 0.25)
                : CrusaderGrays.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: accents.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                widget.filename,
                style: TextStyle(
                  fontSize: 12,
                  color: CrusaderGrays.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.size,
              style: TextStyle(fontSize: 10, color: CrusaderGrays.muted),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onRemove,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.5,
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: CrusaderGrays.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip Input Field — To / Cc / Bcc with chip display
// ─────────────────────────────────────────────────────────────────────────────

class _ChipInputField extends StatelessWidget {
  const _ChipInputField({
    required this.label,
    required this.controller,
    required this.chips,
    required this.onSubmit,
    required this.onRemoveChip,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final List<String> chips;
  final VoidCallback onSubmit;
  final ValueChanged<int> onRemoveChip;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: CrusaderGrays.muted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips.asMap().entries.map((entry) {
                  return _EmailChip(
                    email: entry.value,
                    onRemove: () => onRemoveChip(entry.key),
                  );
                }),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => onSubmit(),
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: chips.isEmpty ? 'Add recipient...' : '',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: CrusaderGrays.subtle,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EmailChip extends StatefulWidget {
  const _EmailChip({required this.email, required this.onRemove});

  final String email;
  final VoidCallback onRemove;

  @override
  State<_EmailChip> createState() => _EmailChipState();
}

class _EmailChipState extends State<_EmailChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isHovered
              ? accents.primary.withValues(alpha: 0.15)
              : accents.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: accents.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.email,
              style: TextStyle(
                fontSize: 12,
                color: accents.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: widget.onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: accents.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.9, end: 1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatting Toolbar Button
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered ? CrusaderGrays.primary : CrusaderGrays.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: CrusaderGrays.border.withValues(alpha: 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compose Action Button — header icon buttons with optional badge
// ─────────────────────────────────────────────────────────────────────────────

class _ComposeAction extends StatefulWidget {
  const _ComposeAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  State<_ComposeAction> createState() => _ComposeActionState();
}

class _ComposeActionState extends State<_ComposeAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isHovered
                      ? CrusaderGrays.primary
                      : CrusaderGrays.muted,
                ),
                // Badge dot for attachment count
                if (widget.badgeCount > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accents.primary,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.badgeCount}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send Button — gradient with keyboard shortcut + loading state
// ─────────────────────────────────────────────────────────────────────────────

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.accents,
    required this.textTheme,
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.canSend ? 1.0 : 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.canSend ? widget.onSend : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: _isHovered && widget.canSend
                    ? [
                        widget.accents.primary,
                        widget.accents.secondary.withValues(alpha: 0.8),
                      ]
                    : [
                        widget.accents.primary.withValues(alpha: 0.85),
                        widget.accents.secondary.withValues(alpha: 0.65),
                      ],
              ),
              boxShadow: _isHovered && widget.canSend
                  ? [
                      BoxShadow(
                        color: widget.accents.primaryGlow.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 14,
                        spreadRadius: -3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isSending)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.isSending ? 'Sending...' : 'Send',
                  style: widget.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!widget.isSending) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      'Ctrl+Enter',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
