/// Crusader — Drift Database Schema
///
/// Local SQLite cache for offline-first email. Defines tables for
/// cached emails, mailboxes, and sync metadata.
///
/// Run `dart run build_runner build` to regenerate `database.g.dart`.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Table Definitions
// ─────────────────────────────────────────────────────────────────────────────

/// Cached email messages.
class CachedEmails extends Table {
  // Primary key: local uuid
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get mailboxPath => text()();
  IntColumn get uid => integer()();

  // Envelope
  TextColumn get fromAddress => text()();
  TextColumn get fromName => text().nullable()();
  TextColumn get toAddresses => text()(); // JSON-encoded list
  TextColumn get ccAddresses => text().withDefault(const Constant('[]'))();
  TextColumn get subject => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();

  // Body
  TextColumn get textPlain => text().nullable()();
  TextColumn get textHtml => text().nullable()();
  TextColumn get snippet => text().withDefault(const Constant(''))();

  // Flags (comma-separated: "seen,flagged")
  TextColumn get flags => text().withDefault(const Constant(''))();

  // Threading headers
  TextColumn get messageId => text().nullable()();
  TextColumn get inReplyTo => text().nullable()();
  TextColumn get references =>
      text().withDefault(const Constant(''))(); // comma-separated
  TextColumn get threadId => text().nullable()();

  // Metadata
  IntColumn get size => integer().withDefault(const Constant(0))();
  BoolColumn get hasAttachments =>
      boolean().withDefault(const Constant(false))();
  IntColumn get attachmentCount => integer().withDefault(const Constant(0))();
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();

  // Snooze
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  BoolColumn get isSnoozed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId, mailboxPath, uid},
  ];
}

/// Cached mailbox / folder metadata.
class CachedMailboxes extends Table {
  TextColumn get path => text()();
  TextColumn get name => text()();
  TextColumn get accountId => text()();
  TextColumn get role => text().withDefault(const Constant('custom'))();
  IntColumn get totalMessages => integer().withDefault(const Constant(0))();
  IntColumn get unseenMessages => integer().withDefault(const Constant(0))();
  BoolColumn get isSubscribed => boolean().withDefault(const Constant(true))();
  IntColumn get highestModSeq => integer().nullable()();
  IntColumn get uidValidity => integer().nullable()();
  IntColumn get uidNext => integer().nullable()();

  @override
  Set<Column> get primaryKey => {path, accountId};
}

/// Sync metadata — tracks sync state per account+mailbox.
class SyncState extends Table {
  TextColumn get accountId => text()();
  TextColumn get mailboxPath => text()();
  IntColumn get lastSyncedUid => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  IntColumn get uidValidity => integer().nullable()();

  @override
  Set<Column> get primaryKey => {accountId, mailboxPath};
}

// ─────────────────────────────────────────────────────────────────────────────
// Database Class
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [CachedEmails, CachedMailboxes, SyncState])
class CrusaderDatabase extends _$CrusaderDatabase {
  CrusaderDatabase() : super(_openConnection());

  /// For testing — inject a custom executor.
  CrusaderDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Create performance indexes.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_emails_account_mailbox_date '
        'ON cached_emails (account_id, mailbox_path, date DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_emails_account_thread '
        'ON cached_emails (account_id, thread_id)',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add attachmentsJson column (schema v2).
        // Wrapped in try-catch: the column may already exist if the
        // migration ran partially or the DB file was reused.
        try {
          await customStatement(
            "ALTER TABLE cached_emails ADD COLUMN attachments_json TEXT NOT NULL DEFAULT '[]'",
          );
        } on Exception {
          // Column already exists — safe to ignore.
        }
      }
      if (from < 3) {
        // Add snooze columns (schema v3).
        try {
          await customStatement(
            'ALTER TABLE cached_emails ADD COLUMN snoozed_until INTEGER',
          );
        } on Exception {
          // Column already exists — safe to ignore.
        }
        try {
          await customStatement(
            'ALTER TABLE cached_emails ADD COLUMN is_snoozed INTEGER NOT NULL DEFAULT 0',
          );
        } on Exception {
          // Column already exists — safe to ignore.
        }
      }
    },
  );

  // ── Email Queries ───────────────────────────────────────────────────────

  /// Get all emails for an account+mailbox, newest first (max 200).
  /// Excludes snoozed emails by default.
  Future<List<CachedEmail>> getEmails(
    String accountId,
    String mailboxPath, {
    int limit = 200,
    bool includeSnoozed = false,
  }) async {
    final query = select(cachedEmails)
      ..where(
        (e) =>
            e.accountId.equals(accountId) & e.mailboxPath.equals(mailboxPath),
      )
      ..orderBy([
        (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    if (!includeSnoozed) {
      query.where((e) => e.isSnoozed.equals(false));
    }
    return query.get();
  }

  /// Get a single email by ID.
  Future<CachedEmail?> getEmailById(String id) async {
    return (select(
      cachedEmails,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  /// Get all emails for a thread ID.
  Future<List<CachedEmail>> getEmailsByThread(
    String accountId,
    String threadId,
  ) async {
    return (select(cachedEmails)
          ..where(
            (e) => e.accountId.equals(accountId) & e.threadId.equals(threadId),
          )
          ..orderBy([
            (e) => OrderingTerm(expression: e.date, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Upsert an email (insert or replace).
  Future<void> upsertEmail(CachedEmailsCompanion email) async {
    await into(cachedEmails).insertOnConflictUpdate(email);
  }

  /// Upsert a batch of emails.
  Future<void> upsertEmails(List<CachedEmailsCompanion> emails) async {
    await batch((b) {
      for (final email in emails) {
        b.insert(cachedEmails, email, onConflict: DoUpdate((_) => email));
      }
    });
  }

  /// Get an email by (accountId, mailboxPath, uid) — the IMAP natural key.
  Future<CachedEmail?> getEmailByUid(
    String accountId,
    String mailboxPath,
    int uid,
  ) async {
    return (select(cachedEmails)..where(
          (e) =>
              e.accountId.equals(accountId) &
              e.mailboxPath.equals(mailboxPath) &
              e.uid.equals(uid),
        ))
        .getSingleOrNull();
  }

  /// Delete all emails for an account.
  Future<void> deleteEmailsForAccount(String accountId) async {
    await (delete(
      cachedEmails,
    )..where((e) => e.accountId.equals(accountId))).go();
  }

  /// Delete a single email by ID.
  Future<void> deleteEmail(String emailId) async {
    await (delete(cachedEmails)..where((e) => e.id.equals(emailId))).go();
  }

  /// Search emails by text (subject, snippet, from).
  Future<List<CachedEmail>> searchEmails(String accountId, String query) async {
    final pattern = '%$query%';
    return (select(cachedEmails)
          ..where(
            (e) =>
                e.accountId.equals(accountId) &
                (e.subject.like(pattern) |
                    e.snippet.like(pattern) |
                    e.fromAddress.like(pattern) |
                    e.fromName.like(pattern)),
          )
          ..orderBy([
            (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
          ])
          ..limit(50))
        .get();
  }

  /// Get inbox emails across ALL accounts, newest first (max 200).
  /// Used for the "Unified Inbox" view. Excludes snoozed by default.
  Future<List<CachedEmail>> getInboxEmailsAllAccounts({
    List<String>? accountIds,
    int limit = 200,
  }) async {
    final query = select(cachedEmails)
      ..where((e) => e.mailboxPath.equals('INBOX') & e.isSnoozed.equals(false))
      ..orderBy([
        (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    if (accountIds != null && accountIds.isNotEmpty) {
      query.where((e) => e.accountId.isIn(accountIds));
    }
    return query.get();
  }

  /// Update flags for an email.
  Future<void> updateEmailFlags(String emailId, String flags) async {
    await (update(cachedEmails)..where((e) => e.id.equals(emailId))).write(
      CachedEmailsCompanion(flags: Value(flags)),
    );
  }

  /// Bulk-update flags by (accountId, mailboxPath, uid) key.
  Future<void> bulkUpdateFlags(
    String accountId,
    String mailboxPath,
    Map<int, String> uidToFlags,
  ) async {
    for (final entry in uidToFlags.entries) {
      await (update(cachedEmails)..where(
            (e) =>
                e.accountId.equals(accountId) &
                e.mailboxPath.equals(mailboxPath) &
                e.uid.equals(entry.key),
          ))
          .write(CachedEmailsCompanion(flags: Value(entry.value)));
    }
  }

  /// Snooze an email until the specified time.
  Future<void> snoozeEmail(String emailId, DateTime until) async {
    await (update(cachedEmails)..where((e) => e.id.equals(emailId))).write(
      CachedEmailsCompanion(
        isSnoozed: const Value(true),
        snoozedUntil: Value(until),
      ),
    );
  }

  /// Un-snooze an email (clear snooze state).
  Future<void> unsnoozeEmail(String emailId) async {
    await (update(cachedEmails)..where((e) => e.id.equals(emailId))).write(
      const CachedEmailsCompanion(
        isSnoozed: Value(false),
        snoozedUntil: Value(null),
      ),
    );
  }

  /// Get all snoozed emails whose snooze time has elapsed.
  Future<List<CachedEmail>> getSnoozedEmailsDue() async {
    return (select(cachedEmails)..where(
          (e) =>
              e.isSnoozed.equals(true) &
              e.snoozedUntil.isSmallerOrEqualValue(DateTime.now()),
        ))
        .get();
  }

  // ── Mailbox Queries ─────────────────────────────────────────────────────

  /// Get all mailboxes for an account.
  Future<List<CachedMailboxe>> getMailboxes(String accountId) async {
    return (select(cachedMailboxes)
          ..where((m) => m.accountId.equals(accountId))
          ..orderBy([(m) => OrderingTerm.asc(m.name)]))
        .get();
  }

  /// Upsert a mailbox.
  Future<void> upsertMailbox(CachedMailboxesCompanion mailbox) async {
    await into(cachedMailboxes).insertOnConflictUpdate(mailbox);
  }

  /// Upsert a batch of mailboxes.
  Future<void> upsertMailboxes(List<CachedMailboxesCompanion> mailboxes) async {
    await batch((b) {
      for (final mb in mailboxes) {
        b.insert(cachedMailboxes, mb, onConflict: DoUpdate((_) => mb));
      }
    });
  }

  // ── Sync State Queries ──────────────────────────────────────────────────

  /// Get sync state for an account+mailbox.
  Future<SyncStateData?> getSyncState(
    String accountId,
    String mailboxPath,
  ) async {
    return (select(syncState)..where(
          (s) =>
              s.accountId.equals(accountId) & s.mailboxPath.equals(mailboxPath),
        ))
        .getSingleOrNull();
  }

  /// Upsert sync state.
  Future<void> upsertSyncState(SyncStateCompanion state) async {
    await into(syncState).insertOnConflictUpdate(state);
  }

  // ── Utility ─────────────────────────────────────────────────────────────

  /// Clear all data for an account (on account removal).
  Future<void> clearAccountData(String accountId) async {
    await deleteEmailsForAccount(accountId);
    await (delete(
      cachedMailboxes,
    )..where((m) => m.accountId.equals(accountId))).go();
    await (delete(syncState)..where((s) => s.accountId.equals(accountId))).go();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection Factory
// ─────────────────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'crusader.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
