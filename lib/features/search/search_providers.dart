/// Crusader — Search Providers (Riverpod)
///
/// Manages search state: query, results, filters.
/// Uses Drift for local full-text search across cached emails.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/email_repository.dart';
import '../../domain/entities/email_thread.dart';
import '../auth/auth_providers.dart';
import '../inbox/inbox_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Search Filter
// ─────────────────────────────────────────────────────────────────────────────

enum SearchFilter { all, unread, attachments, flagged, fromMe }

// ─────────────────────────────────────────────────────────────────────────────
// Search State
// ─────────────────────────────────────────────────────────────────────────────

class SearchState {
  const SearchState({
    this.query = '',
    this.filter = SearchFilter.all,
    this.results = const [],
    this.isSearching = false,
    this.hasSearched = false,
    this.recentSearches = const [],
  });

  final String query;
  final SearchFilter filter;
  final List<EmailThread> results;
  final bool isSearching;
  final bool hasSearched;
  final List<String> recentSearches;

  bool get hasResults => results.isNotEmpty;

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    List<EmailThread>? results,
    bool? isSearching,
    bool? hasSearched,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Notifier
// ─────────────────────────────────────────────────────────────────────────────

final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(
    emailRepo: ref.read(emailRepositoryProvider),
    ref: ref,
  );
});

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier({
    required EmailRepository emailRepo,
    required Ref ref,
  })  : _emailRepo = emailRepo,
        _ref = ref,
        super(const SearchState());

  final EmailRepository _emailRepo;
  final Ref _ref;

  /// Perform a local search.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        results: [],
        hasSearched: false,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isSearching: true,
      hasSearched: true,
    );

    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) {
      state = state.copyWith(isSearching: false, results: []);
      return;
    }

    try {
      final threads = await _emailRepo.searchThreads(
        account.id,
        query.trim(),
      );

      // Apply filter.
      final filtered = _applyFilter(threads, state.filter, account.email);

      // Add to recent searches (deduplicated, max 10).
      final recents = [
        query.trim(),
        ...state.recentSearches.where((s) => s != query.trim()),
      ].take(10).toList();

      state = state.copyWith(
        results: filtered,
        isSearching: false,
        recentSearches: recents,
      );
    } catch (_) {
      state = state.copyWith(isSearching: false, results: []);
    }
  }

  /// Update the active filter and re-apply.
  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  /// Clear search.
  void clear() {
    state = state.copyWith(
      query: '',
      results: [],
      hasSearched: false,
      isSearching: false,
    );
  }

  List<EmailThread> _applyFilter(
    List<EmailThread> threads,
    SearchFilter filter,
    String myEmail,
  ) {
    switch (filter) {
      case SearchFilter.all:
        return threads;
      case SearchFilter.unread:
        return threads.where((t) => t.hasUnread).toList();
      case SearchFilter.attachments:
        return threads
            .where((t) => t.messages.any((m) => m.hasAttachments))
            .toList();
      case SearchFilter.flagged:
        return threads.where((t) => t.isFlagged).toList();
      case SearchFilter.fromMe:
        return threads
            .where((t) => t.messages.any(
                  (m) => m.from.address.toLowerCase() == myEmail.toLowerCase(),
                ))
            .toList();
    }
  }
}
