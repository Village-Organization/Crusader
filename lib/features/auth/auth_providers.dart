/// Crusader — Auth Providers (Riverpod)
///
/// Provides account state and auth operations to the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/oauth_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/oauth_token.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Singleton Providers
// ─────────────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final oauthServiceProvider = Provider<OAuthService>((ref) {
  return OAuthService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Account State
// ─────────────────────────────────────────────────────────────────────────────

/// Holds all connected accounts and the currently active one.
class AccountState {
  const AccountState({
    this.accounts = const [],
    this.activeAccountId,
    this.isLoading = false,
    this.error,
  });

  final List<EmailAccount> accounts;
  final String? activeAccountId;
  final bool isLoading;
  final String? error;

  EmailAccount? get activeAccount {
    if (activeAccountId == null) return null;
    try {
      return accounts.firstWhere((a) => a.id == activeAccountId);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  bool get hasAccounts => accounts.isNotEmpty;

  AccountState copyWith({
    List<EmailAccount>? accounts,
    String? activeAccountId,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      activeAccountId: activeAccountId ?? this.activeAccountId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Notifier
// ─────────────────────────────────────────────────────────────────────────────

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(
    authRepo: ref.read(authRepositoryProvider),
    oauthService: ref.read(oauthServiceProvider),
  );
});

class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier({
    required AuthRepository authRepo,
    required OAuthService oauthService,
  })  : _authRepo = authRepo,
        _oauthService = oauthService,
        super(const AccountState(isLoading: true)) {
    _init();
  }

  final AuthRepository _authRepo;
  final OAuthService _oauthService;

  /// Load saved accounts on startup.
  Future<void> _init() async {
    try {
      final accounts = await _authRepo.loadAccounts();
      final activeId = await _authRepo.getActiveAccountId();
      state = AccountState(
        accounts: accounts,
        activeAccountId: activeId ?? (accounts.isNotEmpty ? accounts.first.id : null),
      );
    } catch (e) {
      state = AccountState(error: 'Failed to load accounts: $e');
    }
  }

  /// Start OAuth flow for the given provider, save account + token.
  Future<void> addAccount(EmailProvider provider) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _oauthService.authenticate(provider);

      // Check if account already exists.
      final existing = state.accounts.where(
        (a) => a.email == result.userInfo.email && a.provider == provider,
      );
      if (existing.isNotEmpty) {
        // Update token for existing account.
        await _authRepo.saveToken(existing.first.id, result.token);
        state = state.copyWith(
          isLoading: false,
          activeAccountId: existing.first.id,
        );
        return;
      }

      final account = _authRepo.createAccount(
        email: result.userInfo.email,
        displayName: result.userInfo.displayName,
        provider: provider,
        avatarUrl: result.userInfo.avatarUrl,
      );

      await _authRepo.saveAccount(account);
      await _authRepo.saveToken(account.id, result.token);
      await _authRepo.setActiveAccount(account.id);

      state = AccountState(
        accounts: [...state.accounts, account],
        activeAccountId: account.id,
      );
    } on OAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add account: $e',
      );
    }
  }

  /// Switch the active account.
  Future<void> switchAccount(String accountId) async {
    await _authRepo.setActiveAccount(accountId);
    state = state.copyWith(activeAccountId: accountId);
  }

  /// Remove an account.
  Future<void> removeAccount(String accountId) async {
    await _authRepo.removeAccount(accountId);
    final updated = state.accounts.where((a) => a.id != accountId).toList();
    state = AccountState(
      accounts: updated,
      activeAccountId:
          updated.isNotEmpty ? updated.first.id : null,
    );
  }

  /// Get a valid (non-expired) token for an account, refreshing if needed.
  Future<OAuthToken?> getValidToken(String accountId) async {
    final token = await _authRepo.getToken(accountId);
    if (token == null) return null;

    if (!token.isAboutToExpire) return token;

    // Try to refresh.
    if (token.refreshToken == null) return null;

    final account = state.accounts.firstWhere((a) => a.id == accountId);
    try {
      final refreshed = await _oauthService.refreshToken(
        account.provider,
        token.refreshToken!,
      );
      await _authRepo.saveToken(accountId, refreshed);
      return refreshed;
    } catch (_) {
      return null;
    }
  }
}
