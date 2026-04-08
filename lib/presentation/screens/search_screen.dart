/// Crusader — Search Screen
///
/// Email search with:
/// - Animated glass search bar with focus glow
/// - Filter chips (All, Unread, Attachments, Flagged, From me)
/// - Debounced live search via Riverpod searchProvider
/// - Results list using ThreadTile
/// - Recent searches with tap-to-search
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../features/search/search_providers.dart';
import '../widgets/glass_components.dart';
import '../widgets/thread_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  Timer? _debounce;

  /// Map UI filter labels to SearchFilter enum values.
  static const _filterMap = <String, SearchFilter>{
    'All': SearchFilter.all,
    'Unread': SearchFilter.unread,
    'Attachments': SearchFilter.attachments,
    'Flagged': SearchFilter.flagged,
    'From me': SearchFilter.fromMe,
  };

  static const _filterIcons = <String, IconData>{
    'All': Icons.apps_rounded,
    'Unread': Icons.mark_email_unread_outlined,
    'Attachments': Icons.attach_file_rounded,
    'Flagged': Icons.star_outline_rounded,
    'From me': Icons.person_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchProvider.notifier).search(value);
    });
  }

  void _onClear() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _onRecentTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(searchProvider.notifier).search(query);
    _focusNode.requestFocus();
  }

  void _onFilterTap(String label) {
    final filter = _filterMap[label] ?? SearchFilter.all;
    ref.read(searchProvider.notifier).setFilter(filter);
  }

  String _activeFilterLabel(SearchFilter filter) {
    return _filterMap.entries
        .firstWhere((e) => e.value == filter, orElse: () => _filterMap.entries.first)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final searchState = ref.watch(searchProvider);
    final activeLabel = _activeFilterLabel(searchState.filter);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Search',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: -0.04, end: 0, duration: 350.ms),

            const SizedBox(height: 14),

            // ── Search bar ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: glass.panelColor,
                border: Border.all(
                  color: _hasFocus
                      ? accents.primary.withValues(alpha: 0.4)
                      : glass.panelBorderColor,
                  width: glass.borderWidth,
                ),
                boxShadow: _hasFocus
                    ? [
                        BoxShadow(
                          color:
                              accents.primaryGlow.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: glass.panelShadowColor.withValues(
                            alpha: glass.outerShadowOpacity,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _hasFocus
                          ? Icons.search_rounded
                          : Icons.search_outlined,
                      key: ValueKey(_hasFocus),
                      color: _hasFocus
                          ? accents.primary
                          : CrusaderGrays.muted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search emails, people, attachments...',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: CrusaderGrays.muted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        // Immediate search on Enter.
                        _debounce?.cancel();
                        ref.read(searchProvider.notifier).search(value);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _onClear,
                      child: AnimatedOpacity(
                        opacity:
                            _searchController.text.isNotEmpty ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CrusaderGrays.border
                                .withValues(alpha: 0.5),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: CrusaderGrays.secondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  KeyboardShortcutBadge(shortcut: '/'),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 80.ms)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 400.ms,
                  delay: 80.ms,
                ),

            const SizedBox(height: 14),

            // ── Filter chips ──
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterMap.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filterMap.keys.elementAt(index);
                  final icon = _filterIcons[label]!;
                  final isActive = label == activeLabel;
                  return GlassChip(
                    label: label,
                    icon: icon,
                    isActive: isActive,
                    onTap: () => _onFilterTap(label),
                  );
                },
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideX(begin: -0.03, end: 0, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Content ──
            Expanded(
              child: _buildContent(context, searchState, accents, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SearchState searchState,
    CrusaderAccentTheme accents,
    TextTheme textTheme,
  ) {
    // Currently searching — show spinner.
    if (searchState.isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(accents.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for "${searchState.query}"...',
              style: textTheme.bodyMedium?.copyWith(
                color: CrusaderGrays.secondary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      );
    }

    // Has searched but no results.
    if (searchState.hasSearched && !searchState.hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    CrusaderGrays.muted.withValues(alpha: 0.12),
                    CrusaderGrays.subtle.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 24,
                color: CrusaderGrays.muted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: textTheme.bodyLarge?.copyWith(
                color: CrusaderGrays.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different keywords or filters',
              style: textTheme.bodySmall?.copyWith(
                color: CrusaderGrays.subtle,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    // Has results — show thread list.
    if (searchState.hasResults) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: searchState.results.length,
        itemBuilder: (context, index) {
          final thread = searchState.results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ThreadTile(
              thread: thread,
              animationDelay: Duration(milliseconds: (index * 30).clamp(0, 300)),
              onTap: () => context.push('/thread/${thread.id}'),
            ),
          );
        },
      );
    }

    // Idle state — show recent searches or welcome.
    return _RecentSearchesView(
      recentSearches: searchState.recentSearches,
      accents: accents,
      textTheme: textTheme,
      onRecentTap: _onRecentTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Searches — idle state with tappable recent queries
// ─────────────────────────────────────────────────────────────────────────────

class _RecentSearchesView extends StatelessWidget {
  const _RecentSearchesView({
    required this.recentSearches,
    required this.accents,
    required this.textTheme,
    required this.onRecentTap,
  });

  final List<String> recentSearches;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final ValueChanged<String> onRecentTap;

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accents.primary.withValues(alpha: 0.12),
                    accents.secondary.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 24,
                color: accents.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search across all your emails',
              style: textTheme.bodyLarge?.copyWith(
                color: CrusaderGrays.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find messages by sender, subject, or content',
              style: textTheme.bodySmall?.copyWith(
                color: CrusaderGrays.subtle,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
      );
    }

    // Show recent searches list.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT SEARCHES',
          style: textTheme.labelSmall?.copyWith(
            color: CrusaderGrays.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final query = recentSearches[index];
              return _RecentSearchItem(
                query: query,
                accents: accents,
                textTheme: textTheme,
                onTap: () => onRecentTap(query),
                delay: Duration(milliseconds: index * 40),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}

class _RecentSearchItem extends StatefulWidget {
  const _RecentSearchItem({
    required this.query,
    required this.accents,
    required this.textTheme,
    required this.onTap,
    required this.delay,
  });

  final String query;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_RecentSearchItem> createState() => _RecentSearchItemState();
}

class _RecentSearchItemState extends State<_RecentSearchItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: _isHovered
                      ? widget.accents.primary
                      : CrusaderGrays.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.query,
                    style: widget.textTheme.bodyMedium?.copyWith(
                      color: _isHovered
                          ? CrusaderGrays.bright
                          : CrusaderGrays.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isHovered)
                  Icon(
                    Icons.north_west_rounded,
                    size: 13,
                    color: CrusaderGrays.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: widget.delay)
        .fadeIn(duration: 250.ms)
        .slideX(begin: -0.02, end: 0, duration: 250.ms);
  }
}
