/// Crusader — Thread Detail Screen
///
/// Conversation view showing all messages in a thread.
/// Glassmorphic cards, collapsible messages, HTML rendering.
/// Action bar with reply, forward, archive, delete.
/// Supports both standalone and embedded (master-detail) modes.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/email_message.dart';
import '../../domain/entities/email_thread.dart';
import '../../features/compose/compose_providers.dart';
import '../../features/inbox/inbox_providers.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_panel.dart';
import '../widgets/snooze_picker.dart';

class ThreadDetailScreen extends ConsumerWidget {
  const ThreadDetailScreen({
    super.key,
    required this.threadId,
    this.embedded = false,
  });

  final String threadId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadAsync = ref.watch(threadDetailProvider(threadId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
                  padding: EdgeInsets.fromLTRB(embedded ? 16 : 8, 12, 16, 0),
                  child: Row(
                    children: [
                      if (!embedded) ...[
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            foregroundColor: CrusaderGrays.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: threadAsync.when(
                          data: (thread) => thread != null
                              ? Text(
                                  thread.subject,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox.shrink(),
                          loading: () => ShimmerSkeleton(
                            width: 200,
                            height: 16,
                            borderRadius: 4,
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Action buttons ──
                      _ActionButton(
                        icon: Icons.reply_rounded,
                        tooltip: 'Reply',
                        onPressed: () {
                          final thread = ref
                              .read(threadDetailProvider(threadId))
                              .valueOrNull;
                          if (thread != null) {
                            ref
                                .read(composeProvider.notifier)
                                .prepareReply(thread.latest);
                            context.go('/compose');
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.forward_rounded,
                        tooltip: 'Forward',
                        onPressed: () {
                          final thread = ref
                              .read(threadDetailProvider(threadId))
                              .valueOrNull;
                          if (thread != null) {
                            ref
                                .read(composeProvider.notifier)
                                .prepareForward(thread.latest);
                            context.go('/compose');
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.archive_outlined,
                        tooltip: 'Archive',
                        onPressed: () {
                          final thread = ref
                              .read(threadDetailProvider(threadId))
                              .valueOrNull;
                          if (thread != null) {
                            ref
                                .read(inboxProvider.notifier)
                                .archiveThread(thread);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Archived'),
                                backgroundColor: CrusaderAccents.green,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            if (!embedded) context.pop();
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.snooze_rounded,
                        tooltip: 'Snooze',
                        onPressed: () async {
                          final thread = ref
                              .read(threadDetailProvider(threadId))
                              .valueOrNull;
                          if (thread == null) return;
                          final until = await showSnoozePicker(context);
                          if (until != null && context.mounted) {
                            ref
                                .read(inboxProvider.notifier)
                                .snoozeThread(thread, until);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Snoozed'),
                                backgroundColor: CrusaderAccents.gold,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            if (!embedded) context.pop();
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete',
                        onPressed: () {
                          final thread = ref
                              .read(threadDetailProvider(threadId))
                              .valueOrNull;
                          if (thread != null) {
                            ref
                                .read(inboxProvider.notifier)
                                .moveThreadToTrash(thread);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Moved to Trash'),
                                backgroundColor: CrusaderAccents.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            if (!embedded) context.pop();
                          }
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: -0.04, end: 0, duration: 280.ms),

            const SizedBox(height: 8),
            const GlassDivider(indent: 16, endIndent: 16),

            // ── Content ──
            Expanded(
              child: threadAsync.when(
                data: (thread) {
                  if (thread == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 32,
                            color: CrusaderGrays.subtle,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Thread not found',
                            style: textTheme.bodyLarge?.copyWith(
                              color: CrusaderGrays.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _ThreadContent(thread: thread);
                },
                loading: () => const _ThreadSkeleton(),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading thread',
                    style: textTheme.bodyLarge?.copyWith(
                      color: CrusaderGrays.muted,
                    ),
                  ),
                ),
              ),
            ),

            // ── Quick reply bar ──
            GestureDetector(
                  onTap: () {
                    final thread = ref
                        .read(threadDetailProvider(threadId))
                        .valueOrNull;
                    if (thread != null) {
                      ref
                          .read(composeProvider.notifier)
                          .prepareReply(thread.latest);
                      context.go('/compose');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: CrusaderGrays.border.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderRadius: 12,
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: CrusaderGrays.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Reply...',
                              style: textTheme.bodyMedium?.copyWith(
                                color: CrusaderGrays.muted,
                              ),
                            ),
                          ),
                          KeyboardShortcutBadge(shortcut: 'R'),
                        ],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideY(begin: 0.04, end: 0, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button — compact icon button in the top bar
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _isHovered
                  ? (widget.isDestructive
                        ? accents.error.withValues(alpha: 0.1)
                        : CrusaderGrays.border.withValues(alpha: 0.4))
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: _isHovered
                  ? (widget.isDestructive
                        ? accents.error
                        : CrusaderGrays.primary)
                  : CrusaderGrays.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thread Content — scrollable list of messages
// ─────────────────────────────────────────────────────────────────────────────

class _ThreadContent extends StatelessWidget {
  const _ThreadContent({required this.thread});

  final EmailThread thread;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: thread.messages.length,
        itemBuilder: (context, index) {
          final message = thread.messages[index];
          final isLatest = index == thread.messages.length - 1;
          return _MessageCard(
            message: message,
            isExpanded: isLatest,
            animationDelay: Duration(milliseconds: index * 50),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thread Skeleton — loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _ThreadSkeleton extends StatelessWidget {
  const _ThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassPanel(
              padding: const EdgeInsets.all(16),
              borderRadius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ShimmerSkeleton(height: 32, isCircle: true),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerSkeleton(width: 120 + index * 20, height: 12),
                          const SizedBox(height: 6),
                          const ShimmerSkeleton(width: 80, height: 10),
                        ],
                      ),
                      const Spacer(),
                      const ShimmerSkeleton(width: 50, height: 10),
                    ],
                  ),
                  if (index == 2) ...[
                    const SizedBox(height: 14),
                    const ShimmerSkeleton(height: 10),
                    const SizedBox(height: 6),
                    const ShimmerSkeleton(height: 10),
                    const SizedBox(height: 6),
                    const ShimmerSkeleton(width: 200, height: 10),
                  ],
                ],
              ),
            ),
          ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms);
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Card — single email in the thread
// ─────────────────────────────────────────────────────────────────────────────

class _MessageCard extends ConsumerStatefulWidget {
  const _MessageCard({
    required this.message,
    this.isExpanded = false,
    this.animationDelay = Duration.zero,
  });

  final EmailMessage message;
  final bool isExpanded;
  final Duration animationDelay;

  @override
  ConsumerState<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends ConsumerState<_MessageCard> {
  late bool _isExpanded;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final message = widget.message;

    // Gravatar lookup.
    final avatarBytes = ref
        .watch(avatarProvider(message.from.address))
        .valueOrNull;

    final shouldAnimate = !_hasAnimated;
    if (!_hasAnimated) _hasAnimated = true;

    Widget card = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (always visible, clickable) ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SenderAvatar(
                          initial: message.from.initial,
                          color: accents.primary,
                          size: 32,
                          fontSize: 13,
                          avatarBytes: avatarBytes,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sender name (always)
                            Text(
                              message.from.shortLabel,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Collapsed: show snippet
                            if (!_isExpanded)
                              Text(
                                message.snippet,
                                style: textTheme.bodySmall?.copyWith(
                                  color: CrusaderGrays.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                            // Expanded: show full email metadata
                            if (_isExpanded) ...[
                              const SizedBox(height: 6),
                              _MetadataRow(
                                label: 'From',
                                value: message.from.label,
                                textTheme: textTheme,
                              ),
                              _MetadataRow(
                                label: 'To',
                                value: message.to
                                    .map((a) => a.label)
                                    .join(', '),
                                textTheme: textTheme,
                              ),
                              if (message.cc.isNotEmpty)
                                _MetadataRow(
                                  label: 'Cc',
                                  value: message.cc
                                      .map((a) => a.label)
                                      .join(', '),
                                  textTheme: textTheme,
                                ),
                              if (message.replyTo.isNotEmpty &&
                                  message.replyTo.first.address !=
                                      message.from.address)
                                _MetadataRow(
                                  label: 'Reply-To',
                                  value: message.replyTo
                                      .map((a) => a.label)
                                      .join(', '),
                                  textTheme: textTheme,
                                ),
                              _MetadataRow(
                                label: 'Date',
                                value: DateFormat(
                                  'EEE, MMM d, yyyy \'at\' h:mm a',
                                ).format(message.date.toLocal()),
                                textTheme: textTheme,
                              ),
                              _MetadataRow(
                                label: 'Subject',
                                value: message.subject,
                                textTheme: textTheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            message.relativeDate,
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: CrusaderGrays.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body (collapsible) ──
            // AnimatedCrossFade queries intrinsic sizes which crashes
            // with LayoutBuilder / HtmlWidget table internals.
            // Use AnimatedSize + conditional instead.
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? _MessageBody(message: message)
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldAnimate) {
      card = card
          .animate(delay: widget.animationDelay)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.03, end: 0, duration: 300.ms);
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata Row — single label:value pair in expanded header
// ─────────────────────────────────────────────────────────────────────────────

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$label:',
              style: textTheme.labelSmall?.copyWith(
                color: CrusaderGrays.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: textTheme.labelSmall?.copyWith(
                color: CrusaderGrays.secondary,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Safe Widget Factory — prevents AspectRatio crash with unbounded constraints
// ─────────────────────────────────────────────────────────────────────────────

class _SafeEmailWidgetFactory extends WidgetFactory {
  @override
  Widget? buildAspectRatio(BuildTree tree, Widget child, double aspectRatio) {
    // NEVER return an AspectRatio widget. The default implementation crashes
    // with "has unbounded constraints" when placed inside HTML table cells,
    // because the table layout algorithm passes unbounded constraints during
    // intrinsic size computation. LayoutBuilder also cannot be used here —
    // it is equally incompatible with intrinsic size queries.
    // Simply return the child; images will size naturally without forced
    // aspect ratios, which is safe and visually acceptable in email.
    return child;
  }

  @override
  Widget? buildImageWidget(BuildTree tree, ImageSource src) {
    final widget = super.buildImageWidget(tree, src);
    if (widget == null) return null;
    // Constrain every image to sane dimensions. This prevents social media
    // icons and logos from rendering at their massive native resolution.
    // 480px max-width keeps content readable; 400px max-height prevents
    // hero images from dominating the viewport.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
      child: widget,
    );
  }
}

/// Sanitise raw email HTML to prevent layout crashes in flutter_widget_from_html
/// and to ensure readability on our dark background.
///
/// The library's internal `_TableRenderObject` uses `LayoutBuilder` in its
/// scrollable cell wrappers. When the table computes intrinsic column widths
/// it queries children for intrinsic sizes — but `LayoutBuilder` cannot
/// answer those queries, causing a cascade of "RenderBox was not laid out"
/// errors. The only reliable fix is to replace all table structures with
/// simple `<div>` blocks before the library ever sees them.
///
/// Also strips inline colors, background styles, and font sizes so our
/// dark-mode theme colors and sizing take over.
String _sanitiseEmailHtml(String html) {
  var result = html;

  // 1. Replace table structural tags with divs.
  //    Order matters — replace opening tags first, then closing tags.
  result = result.replaceAll(
    RegExp(r'<table\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</table\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<thead\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</thead\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<tbody\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</tbody\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<tfoot\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</tfoot\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<tr\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</tr\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<td\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</td\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<th\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</th\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<caption\b[^>]*>', caseSensitive: false),
    '<div>',
  );
  result = result.replaceAll(
    RegExp(r'</caption\s*>', caseSensitive: false),
    '</div>',
  );
  result = result.replaceAll(
    RegExp(
      r'<colgroup\b[^>]*>.*?</colgroup\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(r'<col\b[^>]*/?\s*>', caseSensitive: false),
    '',
  );

  // 2. Cap image dimensions instead of stripping them entirely.
  //    Small images (icons, logos) need their size preserved, otherwise they
  //    render at their full native resolution. We keep values ≤ 480px and
  //    clamp larger ones down to 480px. Also add max-width:100% for safety.
  final imgTagRe = RegExp(r'<img\b[^>]*>', caseSensitive: false);
  result = result.replaceAllMapped(imgTagRe, (m) {
    var tag = m.group(0)!;
    // Clamp width attribute to max 480
    tag = tag.replaceAllMapped(
      RegExp(r'''(width)\s*=\s*"?(\d+)"?''', caseSensitive: false),
      (dm) {
        final val = int.tryParse(dm.group(2)!) ?? 480;
        final clamped = val > 480 ? 480 : val;
        return 'width="$clamped"';
      },
    );
    // Clamp height attribute to max 400
    tag = tag.replaceAllMapped(
      RegExp(r'''(height)\s*=\s*"?(\d+)"?''', caseSensitive: false),
      (dm) {
        final val = int.tryParse(dm.group(2)!) ?? 400;
        final clamped = val > 400 ? 400 : val;
        return 'height="$clamped"';
      },
    );
    // Inject max-width safety style
    if (!tag.contains('max-width')) {
      tag = tag.replaceFirst(
        RegExp(r'<img\b', caseSensitive: false),
        '<img style="max-width:100%;height:auto"',
      );
    }
    return tag;
  });

  // 4. Strip bgcolor HTML attributes (used on <body>, <td>, <div>, etc.).
  result = result.replaceAll(
    RegExp(
      r'''\s+bgcolor\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)''',
      caseSensitive: false,
    ),
    '',
  );

  // 5. Strip inline color / background CSS properties.
  //    This is critical for dark-mode readability — emails often set dark
  //    text on white backgrounds, which becomes invisible on our dark canvas.
  //    We strip: color, background-color, background (shorthand).
  //    We preserve other style properties by only removing those keys.
  result = result.replaceAll(
    RegExp(
      r'(?<=;|\s|")background-color\s*:\s*[^;\"]+;?',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(r'(?<=;|\s|")background\s*:\s*[^;\"]+;?', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r'(?<=;|\s|")color\s*:\s*[^;\"]+;?', caseSensitive: false),
    '',
  );

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Body — renders HTML or plain text
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Divider
              const GlassDivider(),
              const SizedBox(height: 14),

              // Body content
              _buildBody(context, textTheme),

              // Attachments
              if (message.hasAttachments || message.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _AttachmentSection(attachments: message.attachments),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TextTheme textTheme) {
    if (message.textHtml != null && message.textHtml!.isNotEmpty) {
      // HTML body — sanitised & dark-mode-forced
      return HtmlWidget(
        _sanitiseEmailHtml(message.textHtml!),
        buildAsync: false,
        enableCaching: true,
        factoryBuilder: () => _SafeEmailWidgetFactory(),
        renderMode: RenderMode.column,
        customStylesBuilder: (element) {
          // Force readable light text on dark background.
          // We strip inline color/background in _sanitiseEmailHtml, but
          // some elements may still inherit or have CSS class-based
          // colors. Override everything here.
          final tag = element.localName ?? '';
          final styles = <String, String>{
            'max-width': '100%',
            'overflow-wrap': 'break-word',
            'word-break': 'break-word',
            'color': '#C8C8D8', // CrusaderGrays.primary
          };

          // Links get accent color
          if (tag == 'a') {
            styles['color'] = '#00E5FF'; // CrusaderAccents.cyan
          }

          // Headings get brighter color
          if (tag.startsWith('h')) {
            styles['color'] = '#EAEAF4'; // CrusaderGrays.bright
          }

          // Strip background from all elements
          styles['background-color'] = 'transparent';
          styles['background'] = 'transparent';

          return styles;
        },
        onErrorBuilder: (_, element, error) => Text(
          'Could not render this part of the email',
          style: textTheme.bodySmall?.copyWith(
            color: CrusaderGrays.muted,
            fontStyle: FontStyle.italic,
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: CrusaderGrays.primary,
          height: 1.5,
        ),
      );
    }

    if (message.textPlain != null && message.textPlain!.isNotEmpty) {
      return SelectableText(
        message.textPlain!,
        style: textTheme.bodyMedium?.copyWith(
          color: CrusaderGrays.primary,
          height: 1.5,
        ),
      );
    }

    // Fallback: snippet or loading indicator
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.snippet.isNotEmpty)
          SelectableText(
            message.snippet,
            style: textTheme.bodyMedium?.copyWith(
              color: CrusaderGrays.primary,
              height: 1.5,
            ),
          )
        else ...[
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: CrusaderGrays.muted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading message body\u2026',
                style: textTheme.bodySmall?.copyWith(
                  color: CrusaderGrays.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attachment Section — shows all attachments for a message
// ─────────────────────────────────────────────────────────────────────────────

class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({required this.attachments});

  final List<Attachment> attachments;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // If we have parsed attachments, show them as cards.
    if (attachments.isNotEmpty) {
      // Inline images first, then regular attachments.
      final inlineImages = attachments.where(
        (a) => a.isInline && a.isImage && a.data != null,
      );
      final regularAttachments = attachments.where(
        (a) => !a.isInline || !a.isImage,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 14,
                color: CrusaderGrays.muted,
              ),
              const SizedBox(width: 6),
              Text(
                '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                style: textTheme.labelSmall?.copyWith(
                  color: CrusaderGrays.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Inline image previews
          if (inlineImages.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: inlineImages.map((attachment) {
                return _InlineImagePreview(attachment: attachment);
              }).toList(),
            ),
            if (regularAttachments.isNotEmpty) const SizedBox(height: 10),
          ],

          // Regular attachment cards
          ...regularAttachments.map((attachment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AttachmentCard(attachment: attachment),
            );
          }),
        ],
      );
    }

    // Fallback: no parsed attachments (body not fetched yet).
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: CrusaderGrays.border.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 14,
            color: CrusaderGrays.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Attachments',
            style: textTheme.labelSmall?.copyWith(
              color: CrusaderGrays.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attachment Card — individual file attachment with icon + download
// ─────────────────────────────────────────────────────────────────────────────

class _AttachmentCard extends StatefulWidget {
  const _AttachmentCard({required this.attachment});

  final Attachment attachment;

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _isHovered = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final a = widget.attachment;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _openAttachment(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.5)
                : CrusaderGrays.border.withValues(alpha: 0.25),
            border: Border.all(
              color: _isHovered
                  ? accents.primary.withValues(alpha: 0.3)
                  : CrusaderGrays.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File type icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: _iconColor(a).withValues(alpha: 0.12),
                ),
                child: Icon(_iconData(a), size: 16, color: _iconColor(a)),
              ),
              const SizedBox(width: 10),
              // Filename + size
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.filename,
                      style: textTheme.labelMedium?.copyWith(
                        color: CrusaderGrays.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (a.size > 0)
                      Text(
                        a.humanSize,
                        style: textTheme.labelSmall?.copyWith(
                          color: CrusaderGrays.muted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Download/open button
              if (_isSaving)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accents.primary,
                  ),
                )
              else
                AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: _isHovered ? accents.primary : CrusaderGrays.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context) async {
    final a = widget.attachment;
    if (a.data == null || a.data!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attachment data not available'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${a.filename}');
      await file.writeAsBytes(a.data!);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  IconData _iconData(Attachment a) {
    if (a.isImage) return Icons.image_rounded;
    if (a.isPdf) return Icons.picture_as_pdf_rounded;
    switch (a.extension) {
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
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file_rounded;
      case 'txt':
      case 'md':
      case 'log':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _iconColor(Attachment a) {
    if (a.isImage) return CrusaderAccents.green;
    if (a.isPdf) return CrusaderAccents.red;
    switch (a.extension) {
      case 'doc':
      case 'docx':
        return CrusaderAccents.cyan;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return CrusaderAccents.green;
      case 'ppt':
      case 'pptx':
        return CrusaderAccents.goldMuted;
      case 'zip':
      case 'rar':
      case '7z':
        return CrusaderAccents.gold;
      default:
        return CrusaderGrays.secondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline Image Preview — shows embedded images inline
// ─────────────────────────────────────────────────────────────────────────────

class _InlineImagePreview extends StatelessWidget {
  const _InlineImagePreview({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.data == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 240),
        child: Image.memory(
          attachment.data!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: CrusaderGrays.border.withValues(alpha: 0.3),
            ),
            child: Icon(
              Icons.broken_image_rounded,
              color: CrusaderGrays.muted,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
