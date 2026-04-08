// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedEmailsTable extends CachedEmails
    with TableInfo<$CachedEmailsTable, CachedEmail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEmailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mailboxPathMeta = const VerificationMeta(
    'mailboxPath',
  );
  @override
  late final GeneratedColumn<String> mailboxPath = GeneratedColumn<String>(
    'mailbox_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddressMeta = const VerificationMeta(
    'fromAddress',
  );
  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
    'from_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAddressesMeta = const VerificationMeta(
    'toAddresses',
  );
  @override
  late final GeneratedColumn<String> toAddresses = GeneratedColumn<String>(
    'to_addresses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ccAddressesMeta = const VerificationMeta(
    'ccAddresses',
  );
  @override
  late final GeneratedColumn<String> ccAddresses = GeneratedColumn<String>(
    'cc_addresses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textPlainMeta = const VerificationMeta(
    'textPlain',
  );
  @override
  late final GeneratedColumn<String> textPlain = GeneratedColumn<String>(
    'text_plain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textHtmlMeta = const VerificationMeta(
    'textHtml',
  );
  @override
  late final GeneratedColumn<String> textHtml = GeneratedColumn<String>(
    'text_html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<String> flags = GeneratedColumn<String>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inReplyToMeta = const VerificationMeta(
    'inReplyTo',
  );
  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
    'in_reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referencesMeta = const VerificationMeta(
    'references',
  );
  @override
  late final GeneratedColumn<String> references = GeneratedColumn<String>(
    'references',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasAttachmentsMeta = const VerificationMeta(
    'hasAttachments',
  );
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
    'has_attachments',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_attachments" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attachmentCountMeta = const VerificationMeta(
    'attachmentCount',
  );
  @override
  late final GeneratedColumn<int> attachmentCount = GeneratedColumn<int>(
    'attachment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSnoozedMeta = const VerificationMeta(
    'isSnoozed',
  );
  @override
  late final GeneratedColumn<bool> isSnoozed = GeneratedColumn<bool>(
    'is_snoozed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_snoozed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    mailboxPath,
    uid,
    fromAddress,
    fromName,
    toAddresses,
    ccAddresses,
    subject,
    date,
    textPlain,
    textHtml,
    snippet,
    flags,
    messageId,
    inReplyTo,
    references,
    threadId,
    size,
    hasAttachments,
    attachmentCount,
    attachmentsJson,
    snoozedUntil,
    isSnoozed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_emails';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedEmail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('mailbox_path')) {
      context.handle(
        _mailboxPathMeta,
        mailboxPath.isAcceptableOrUnknown(
          data['mailbox_path']!,
          _mailboxPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mailboxPathMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('from_address')) {
      context.handle(
        _fromAddressMeta,
        fromAddress.isAcceptableOrUnknown(
          data['from_address']!,
          _fromAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAddressMeta);
    }
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    }
    if (data.containsKey('to_addresses')) {
      context.handle(
        _toAddressesMeta,
        toAddresses.isAcceptableOrUnknown(
          data['to_addresses']!,
          _toAddressesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toAddressesMeta);
    }
    if (data.containsKey('cc_addresses')) {
      context.handle(
        _ccAddressesMeta,
        ccAddresses.isAcceptableOrUnknown(
          data['cc_addresses']!,
          _ccAddressesMeta,
        ),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('text_plain')) {
      context.handle(
        _textPlainMeta,
        textPlain.isAcceptableOrUnknown(data['text_plain']!, _textPlainMeta),
      );
    }
    if (data.containsKey('text_html')) {
      context.handle(
        _textHtmlMeta,
        textHtml.isAcceptableOrUnknown(data['text_html']!, _textHtmlMeta),
      );
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
        _inReplyToMeta,
        inReplyTo.isAcceptableOrUnknown(data['in_reply_to']!, _inReplyToMeta),
      );
    }
    if (data.containsKey('references')) {
      context.handle(
        _referencesMeta,
        references.isAcceptableOrUnknown(data['references']!, _referencesMeta),
      );
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
        _hasAttachmentsMeta,
        hasAttachments.isAcceptableOrUnknown(
          data['has_attachments']!,
          _hasAttachmentsMeta,
        ),
      );
    }
    if (data.containsKey('attachment_count')) {
      context.handle(
        _attachmentCountMeta,
        attachmentCount.isAcceptableOrUnknown(
          data['attachment_count']!,
          _attachmentCountMeta,
        ),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('is_snoozed')) {
      context.handle(
        _isSnoozedMeta,
        isSnoozed.isAcceptableOrUnknown(data['is_snoozed']!, _isSnoozedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId, mailboxPath, uid},
  ];
  @override
  CachedEmail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEmail(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mailboxPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mailbox_path'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      fromAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_address'],
      )!,
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      ),
      toAddresses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_addresses'],
      )!,
      ccAddresses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cc_addresses'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      textPlain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_plain'],
      ),
      textHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_html'],
      ),
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      )!,
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flags'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      inReplyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_reply_to'],
      ),
      references: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}references'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      hasAttachments: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_attachments'],
      )!,
      attachmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_count'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      isSnoozed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_snoozed'],
      )!,
    );
  }

  @override
  $CachedEmailsTable createAlias(String alias) {
    return $CachedEmailsTable(attachedDatabase, alias);
  }
}

class CachedEmail extends DataClass implements Insertable<CachedEmail> {
  final String id;
  final String accountId;
  final String mailboxPath;
  final int uid;
  final String fromAddress;
  final String? fromName;
  final String toAddresses;
  final String ccAddresses;
  final String subject;
  final DateTime date;
  final String? textPlain;
  final String? textHtml;
  final String snippet;
  final String flags;
  final String? messageId;
  final String? inReplyTo;
  final String references;
  final String? threadId;
  final int size;
  final bool hasAttachments;
  final int attachmentCount;
  final String attachmentsJson;
  final DateTime? snoozedUntil;
  final bool isSnoozed;
  const CachedEmail({
    required this.id,
    required this.accountId,
    required this.mailboxPath,
    required this.uid,
    required this.fromAddress,
    this.fromName,
    required this.toAddresses,
    required this.ccAddresses,
    required this.subject,
    required this.date,
    this.textPlain,
    this.textHtml,
    required this.snippet,
    required this.flags,
    this.messageId,
    this.inReplyTo,
    required this.references,
    this.threadId,
    required this.size,
    required this.hasAttachments,
    required this.attachmentCount,
    required this.attachmentsJson,
    this.snoozedUntil,
    required this.isSnoozed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['mailbox_path'] = Variable<String>(mailboxPath);
    map['uid'] = Variable<int>(uid);
    map['from_address'] = Variable<String>(fromAddress);
    if (!nullToAbsent || fromName != null) {
      map['from_name'] = Variable<String>(fromName);
    }
    map['to_addresses'] = Variable<String>(toAddresses);
    map['cc_addresses'] = Variable<String>(ccAddresses);
    map['subject'] = Variable<String>(subject);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || textPlain != null) {
      map['text_plain'] = Variable<String>(textPlain);
    }
    if (!nullToAbsent || textHtml != null) {
      map['text_html'] = Variable<String>(textHtml);
    }
    map['snippet'] = Variable<String>(snippet);
    map['flags'] = Variable<String>(flags);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    map['references'] = Variable<String>(references);
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    map['size'] = Variable<int>(size);
    map['has_attachments'] = Variable<bool>(hasAttachments);
    map['attachment_count'] = Variable<int>(attachmentCount);
    map['attachments_json'] = Variable<String>(attachmentsJson);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['is_snoozed'] = Variable<bool>(isSnoozed);
    return map;
  }

  CachedEmailsCompanion toCompanion(bool nullToAbsent) {
    return CachedEmailsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      mailboxPath: Value(mailboxPath),
      uid: Value(uid),
      fromAddress: Value(fromAddress),
      fromName: fromName == null && nullToAbsent
          ? const Value.absent()
          : Value(fromName),
      toAddresses: Value(toAddresses),
      ccAddresses: Value(ccAddresses),
      subject: Value(subject),
      date: Value(date),
      textPlain: textPlain == null && nullToAbsent
          ? const Value.absent()
          : Value(textPlain),
      textHtml: textHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(textHtml),
      snippet: Value(snippet),
      flags: Value(flags),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      inReplyTo: inReplyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(inReplyTo),
      references: Value(references),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      size: Value(size),
      hasAttachments: Value(hasAttachments),
      attachmentCount: Value(attachmentCount),
      attachmentsJson: Value(attachmentsJson),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      isSnoozed: Value(isSnoozed),
    );
  }

  factory CachedEmail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEmail(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      mailboxPath: serializer.fromJson<String>(json['mailboxPath']),
      uid: serializer.fromJson<int>(json['uid']),
      fromAddress: serializer.fromJson<String>(json['fromAddress']),
      fromName: serializer.fromJson<String?>(json['fromName']),
      toAddresses: serializer.fromJson<String>(json['toAddresses']),
      ccAddresses: serializer.fromJson<String>(json['ccAddresses']),
      subject: serializer.fromJson<String>(json['subject']),
      date: serializer.fromJson<DateTime>(json['date']),
      textPlain: serializer.fromJson<String?>(json['textPlain']),
      textHtml: serializer.fromJson<String?>(json['textHtml']),
      snippet: serializer.fromJson<String>(json['snippet']),
      flags: serializer.fromJson<String>(json['flags']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      inReplyTo: serializer.fromJson<String?>(json['inReplyTo']),
      references: serializer.fromJson<String>(json['references']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      size: serializer.fromJson<int>(json['size']),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      attachmentCount: serializer.fromJson<int>(json['attachmentCount']),
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      isSnoozed: serializer.fromJson<bool>(json['isSnoozed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'mailboxPath': serializer.toJson<String>(mailboxPath),
      'uid': serializer.toJson<int>(uid),
      'fromAddress': serializer.toJson<String>(fromAddress),
      'fromName': serializer.toJson<String?>(fromName),
      'toAddresses': serializer.toJson<String>(toAddresses),
      'ccAddresses': serializer.toJson<String>(ccAddresses),
      'subject': serializer.toJson<String>(subject),
      'date': serializer.toJson<DateTime>(date),
      'textPlain': serializer.toJson<String?>(textPlain),
      'textHtml': serializer.toJson<String?>(textHtml),
      'snippet': serializer.toJson<String>(snippet),
      'flags': serializer.toJson<String>(flags),
      'messageId': serializer.toJson<String?>(messageId),
      'inReplyTo': serializer.toJson<String?>(inReplyTo),
      'references': serializer.toJson<String>(references),
      'threadId': serializer.toJson<String?>(threadId),
      'size': serializer.toJson<int>(size),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'attachmentCount': serializer.toJson<int>(attachmentCount),
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'isSnoozed': serializer.toJson<bool>(isSnoozed),
    };
  }

  CachedEmail copyWith({
    String? id,
    String? accountId,
    String? mailboxPath,
    int? uid,
    String? fromAddress,
    Value<String?> fromName = const Value.absent(),
    String? toAddresses,
    String? ccAddresses,
    String? subject,
    DateTime? date,
    Value<String?> textPlain = const Value.absent(),
    Value<String?> textHtml = const Value.absent(),
    String? snippet,
    String? flags,
    Value<String?> messageId = const Value.absent(),
    Value<String?> inReplyTo = const Value.absent(),
    String? references,
    Value<String?> threadId = const Value.absent(),
    int? size,
    bool? hasAttachments,
    int? attachmentCount,
    String? attachmentsJson,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    bool? isSnoozed,
  }) => CachedEmail(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    mailboxPath: mailboxPath ?? this.mailboxPath,
    uid: uid ?? this.uid,
    fromAddress: fromAddress ?? this.fromAddress,
    fromName: fromName.present ? fromName.value : this.fromName,
    toAddresses: toAddresses ?? this.toAddresses,
    ccAddresses: ccAddresses ?? this.ccAddresses,
    subject: subject ?? this.subject,
    date: date ?? this.date,
    textPlain: textPlain.present ? textPlain.value : this.textPlain,
    textHtml: textHtml.present ? textHtml.value : this.textHtml,
    snippet: snippet ?? this.snippet,
    flags: flags ?? this.flags,
    messageId: messageId.present ? messageId.value : this.messageId,
    inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
    references: references ?? this.references,
    threadId: threadId.present ? threadId.value : this.threadId,
    size: size ?? this.size,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    attachmentCount: attachmentCount ?? this.attachmentCount,
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    isSnoozed: isSnoozed ?? this.isSnoozed,
  );
  CachedEmail copyWithCompanion(CachedEmailsCompanion data) {
    return CachedEmail(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mailboxPath: data.mailboxPath.present
          ? data.mailboxPath.value
          : this.mailboxPath,
      uid: data.uid.present ? data.uid.value : this.uid,
      fromAddress: data.fromAddress.present
          ? data.fromAddress.value
          : this.fromAddress,
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      toAddresses: data.toAddresses.present
          ? data.toAddresses.value
          : this.toAddresses,
      ccAddresses: data.ccAddresses.present
          ? data.ccAddresses.value
          : this.ccAddresses,
      subject: data.subject.present ? data.subject.value : this.subject,
      date: data.date.present ? data.date.value : this.date,
      textPlain: data.textPlain.present ? data.textPlain.value : this.textPlain,
      textHtml: data.textHtml.present ? data.textHtml.value : this.textHtml,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      flags: data.flags.present ? data.flags.value : this.flags,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : this.inReplyTo,
      references: data.references.present
          ? data.references.value
          : this.references,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      size: data.size.present ? data.size.value : this.size,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      attachmentCount: data.attachmentCount.present
          ? data.attachmentCount.value
          : this.attachmentCount,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      isSnoozed: data.isSnoozed.present ? data.isSnoozed.value : this.isSnoozed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEmail(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('mailboxPath: $mailboxPath, ')
          ..write('uid: $uid, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromName: $fromName, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('subject: $subject, ')
          ..write('date: $date, ')
          ..write('textPlain: $textPlain, ')
          ..write('textHtml: $textHtml, ')
          ..write('snippet: $snippet, ')
          ..write('flags: $flags, ')
          ..write('messageId: $messageId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('references: $references, ')
          ..write('threadId: $threadId, ')
          ..write('size: $size, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('isSnoozed: $isSnoozed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    mailboxPath,
    uid,
    fromAddress,
    fromName,
    toAddresses,
    ccAddresses,
    subject,
    date,
    textPlain,
    textHtml,
    snippet,
    flags,
    messageId,
    inReplyTo,
    references,
    threadId,
    size,
    hasAttachments,
    attachmentCount,
    attachmentsJson,
    snoozedUntil,
    isSnoozed,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEmail &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.mailboxPath == this.mailboxPath &&
          other.uid == this.uid &&
          other.fromAddress == this.fromAddress &&
          other.fromName == this.fromName &&
          other.toAddresses == this.toAddresses &&
          other.ccAddresses == this.ccAddresses &&
          other.subject == this.subject &&
          other.date == this.date &&
          other.textPlain == this.textPlain &&
          other.textHtml == this.textHtml &&
          other.snippet == this.snippet &&
          other.flags == this.flags &&
          other.messageId == this.messageId &&
          other.inReplyTo == this.inReplyTo &&
          other.references == this.references &&
          other.threadId == this.threadId &&
          other.size == this.size &&
          other.hasAttachments == this.hasAttachments &&
          other.attachmentCount == this.attachmentCount &&
          other.attachmentsJson == this.attachmentsJson &&
          other.snoozedUntil == this.snoozedUntil &&
          other.isSnoozed == this.isSnoozed);
}

class CachedEmailsCompanion extends UpdateCompanion<CachedEmail> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> mailboxPath;
  final Value<int> uid;
  final Value<String> fromAddress;
  final Value<String?> fromName;
  final Value<String> toAddresses;
  final Value<String> ccAddresses;
  final Value<String> subject;
  final Value<DateTime> date;
  final Value<String?> textPlain;
  final Value<String?> textHtml;
  final Value<String> snippet;
  final Value<String> flags;
  final Value<String?> messageId;
  final Value<String?> inReplyTo;
  final Value<String> references;
  final Value<String?> threadId;
  final Value<int> size;
  final Value<bool> hasAttachments;
  final Value<int> attachmentCount;
  final Value<String> attachmentsJson;
  final Value<DateTime?> snoozedUntil;
  final Value<bool> isSnoozed;
  final Value<int> rowid;
  const CachedEmailsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.mailboxPath = const Value.absent(),
    this.uid = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toAddresses = const Value.absent(),
    this.ccAddresses = const Value.absent(),
    this.subject = const Value.absent(),
    this.date = const Value.absent(),
    this.textPlain = const Value.absent(),
    this.textHtml = const Value.absent(),
    this.snippet = const Value.absent(),
    this.flags = const Value.absent(),
    this.messageId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.references = const Value.absent(),
    this.threadId = const Value.absent(),
    this.size = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.isSnoozed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEmailsCompanion.insert({
    required String id,
    required String accountId,
    required String mailboxPath,
    required int uid,
    required String fromAddress,
    this.fromName = const Value.absent(),
    required String toAddresses,
    this.ccAddresses = const Value.absent(),
    this.subject = const Value.absent(),
    required DateTime date,
    this.textPlain = const Value.absent(),
    this.textHtml = const Value.absent(),
    this.snippet = const Value.absent(),
    this.flags = const Value.absent(),
    this.messageId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.references = const Value.absent(),
    this.threadId = const Value.absent(),
    this.size = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.attachmentCount = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.isSnoozed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       mailboxPath = Value(mailboxPath),
       uid = Value(uid),
       fromAddress = Value(fromAddress),
       toAddresses = Value(toAddresses),
       date = Value(date);
  static Insertable<CachedEmail> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? mailboxPath,
    Expression<int>? uid,
    Expression<String>? fromAddress,
    Expression<String>? fromName,
    Expression<String>? toAddresses,
    Expression<String>? ccAddresses,
    Expression<String>? subject,
    Expression<DateTime>? date,
    Expression<String>? textPlain,
    Expression<String>? textHtml,
    Expression<String>? snippet,
    Expression<String>? flags,
    Expression<String>? messageId,
    Expression<String>? inReplyTo,
    Expression<String>? references,
    Expression<String>? threadId,
    Expression<int>? size,
    Expression<bool>? hasAttachments,
    Expression<int>? attachmentCount,
    Expression<String>? attachmentsJson,
    Expression<DateTime>? snoozedUntil,
    Expression<bool>? isSnoozed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (mailboxPath != null) 'mailbox_path': mailboxPath,
      if (uid != null) 'uid': uid,
      if (fromAddress != null) 'from_address': fromAddress,
      if (fromName != null) 'from_name': fromName,
      if (toAddresses != null) 'to_addresses': toAddresses,
      if (ccAddresses != null) 'cc_addresses': ccAddresses,
      if (subject != null) 'subject': subject,
      if (date != null) 'date': date,
      if (textPlain != null) 'text_plain': textPlain,
      if (textHtml != null) 'text_html': textHtml,
      if (snippet != null) 'snippet': snippet,
      if (flags != null) 'flags': flags,
      if (messageId != null) 'message_id': messageId,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (references != null) 'references': references,
      if (threadId != null) 'thread_id': threadId,
      if (size != null) 'size': size,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (attachmentCount != null) 'attachment_count': attachmentCount,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (isSnoozed != null) 'is_snoozed': isSnoozed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEmailsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? mailboxPath,
    Value<int>? uid,
    Value<String>? fromAddress,
    Value<String?>? fromName,
    Value<String>? toAddresses,
    Value<String>? ccAddresses,
    Value<String>? subject,
    Value<DateTime>? date,
    Value<String?>? textPlain,
    Value<String?>? textHtml,
    Value<String>? snippet,
    Value<String>? flags,
    Value<String?>? messageId,
    Value<String?>? inReplyTo,
    Value<String>? references,
    Value<String?>? threadId,
    Value<int>? size,
    Value<bool>? hasAttachments,
    Value<int>? attachmentCount,
    Value<String>? attachmentsJson,
    Value<DateTime?>? snoozedUntil,
    Value<bool>? isSnoozed,
    Value<int>? rowid,
  }) {
    return CachedEmailsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      mailboxPath: mailboxPath ?? this.mailboxPath,
      uid: uid ?? this.uid,
      fromAddress: fromAddress ?? this.fromAddress,
      fromName: fromName ?? this.fromName,
      toAddresses: toAddresses ?? this.toAddresses,
      ccAddresses: ccAddresses ?? this.ccAddresses,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      textPlain: textPlain ?? this.textPlain,
      textHtml: textHtml ?? this.textHtml,
      snippet: snippet ?? this.snippet,
      flags: flags ?? this.flags,
      messageId: messageId ?? this.messageId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      references: references ?? this.references,
      threadId: threadId ?? this.threadId,
      size: size ?? this.size,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mailboxPath.present) {
      map['mailbox_path'] = Variable<String>(mailboxPath.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (fromAddress.present) {
      map['from_address'] = Variable<String>(fromAddress.value);
    }
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (toAddresses.present) {
      map['to_addresses'] = Variable<String>(toAddresses.value);
    }
    if (ccAddresses.present) {
      map['cc_addresses'] = Variable<String>(ccAddresses.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (textPlain.present) {
      map['text_plain'] = Variable<String>(textPlain.value);
    }
    if (textHtml.present) {
      map['text_html'] = Variable<String>(textHtml.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (flags.present) {
      map['flags'] = Variable<String>(flags.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (inReplyTo.present) {
      map['in_reply_to'] = Variable<String>(inReplyTo.value);
    }
    if (references.present) {
      map['references'] = Variable<String>(references.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (attachmentCount.present) {
      map['attachment_count'] = Variable<int>(attachmentCount.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (isSnoozed.present) {
      map['is_snoozed'] = Variable<bool>(isSnoozed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEmailsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('mailboxPath: $mailboxPath, ')
          ..write('uid: $uid, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromName: $fromName, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('subject: $subject, ')
          ..write('date: $date, ')
          ..write('textPlain: $textPlain, ')
          ..write('textHtml: $textHtml, ')
          ..write('snippet: $snippet, ')
          ..write('flags: $flags, ')
          ..write('messageId: $messageId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('references: $references, ')
          ..write('threadId: $threadId, ')
          ..write('size: $size, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('attachmentCount: $attachmentCount, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('isSnoozed: $isSnoozed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMailboxesTable extends CachedMailboxes
    with TableInfo<$CachedMailboxesTable, CachedMailboxe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMailboxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('custom'),
  );
  static const VerificationMeta _totalMessagesMeta = const VerificationMeta(
    'totalMessages',
  );
  @override
  late final GeneratedColumn<int> totalMessages = GeneratedColumn<int>(
    'total_messages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unseenMessagesMeta = const VerificationMeta(
    'unseenMessages',
  );
  @override
  late final GeneratedColumn<int> unseenMessages = GeneratedColumn<int>(
    'unseen_messages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSubscribedMeta = const VerificationMeta(
    'isSubscribed',
  );
  @override
  late final GeneratedColumn<bool> isSubscribed = GeneratedColumn<bool>(
    'is_subscribed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscribed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _highestModSeqMeta = const VerificationMeta(
    'highestModSeq',
  );
  @override
  late final GeneratedColumn<int> highestModSeq = GeneratedColumn<int>(
    'highest_mod_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidNextMeta = const VerificationMeta(
    'uidNext',
  );
  @override
  late final GeneratedColumn<int> uidNext = GeneratedColumn<int>(
    'uid_next',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    path,
    name,
    accountId,
    role,
    totalMessages,
    unseenMessages,
    isSubscribed,
    highestModSeq,
    uidValidity,
    uidNext,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_mailboxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMailboxe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('total_messages')) {
      context.handle(
        _totalMessagesMeta,
        totalMessages.isAcceptableOrUnknown(
          data['total_messages']!,
          _totalMessagesMeta,
        ),
      );
    }
    if (data.containsKey('unseen_messages')) {
      context.handle(
        _unseenMessagesMeta,
        unseenMessages.isAcceptableOrUnknown(
          data['unseen_messages']!,
          _unseenMessagesMeta,
        ),
      );
    }
    if (data.containsKey('is_subscribed')) {
      context.handle(
        _isSubscribedMeta,
        isSubscribed.isAcceptableOrUnknown(
          data['is_subscribed']!,
          _isSubscribedMeta,
        ),
      );
    }
    if (data.containsKey('highest_mod_seq')) {
      context.handle(
        _highestModSeqMeta,
        highestModSeq.isAcceptableOrUnknown(
          data['highest_mod_seq']!,
          _highestModSeqMeta,
        ),
      );
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    if (data.containsKey('uid_next')) {
      context.handle(
        _uidNextMeta,
        uidNext.isAcceptableOrUnknown(data['uid_next']!, _uidNextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path, accountId};
  @override
  CachedMailboxe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMailboxe(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      totalMessages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_messages'],
      )!,
      unseenMessages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unseen_messages'],
      )!,
      isSubscribed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscribed'],
      )!,
      highestModSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}highest_mod_seq'],
      ),
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      ),
      uidNext: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_next'],
      ),
    );
  }

  @override
  $CachedMailboxesTable createAlias(String alias) {
    return $CachedMailboxesTable(attachedDatabase, alias);
  }
}

class CachedMailboxe extends DataClass implements Insertable<CachedMailboxe> {
  final String path;
  final String name;
  final String accountId;
  final String role;
  final int totalMessages;
  final int unseenMessages;
  final bool isSubscribed;
  final int? highestModSeq;
  final int? uidValidity;
  final int? uidNext;
  const CachedMailboxe({
    required this.path,
    required this.name,
    required this.accountId,
    required this.role,
    required this.totalMessages,
    required this.unseenMessages,
    required this.isSubscribed,
    this.highestModSeq,
    this.uidValidity,
    this.uidNext,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['account_id'] = Variable<String>(accountId);
    map['role'] = Variable<String>(role);
    map['total_messages'] = Variable<int>(totalMessages);
    map['unseen_messages'] = Variable<int>(unseenMessages);
    map['is_subscribed'] = Variable<bool>(isSubscribed);
    if (!nullToAbsent || highestModSeq != null) {
      map['highest_mod_seq'] = Variable<int>(highestModSeq);
    }
    if (!nullToAbsent || uidValidity != null) {
      map['uid_validity'] = Variable<int>(uidValidity);
    }
    if (!nullToAbsent || uidNext != null) {
      map['uid_next'] = Variable<int>(uidNext);
    }
    return map;
  }

  CachedMailboxesCompanion toCompanion(bool nullToAbsent) {
    return CachedMailboxesCompanion(
      path: Value(path),
      name: Value(name),
      accountId: Value(accountId),
      role: Value(role),
      totalMessages: Value(totalMessages),
      unseenMessages: Value(unseenMessages),
      isSubscribed: Value(isSubscribed),
      highestModSeq: highestModSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(highestModSeq),
      uidValidity: uidValidity == null && nullToAbsent
          ? const Value.absent()
          : Value(uidValidity),
      uidNext: uidNext == null && nullToAbsent
          ? const Value.absent()
          : Value(uidNext),
    );
  }

  factory CachedMailboxe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMailboxe(
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      accountId: serializer.fromJson<String>(json['accountId']),
      role: serializer.fromJson<String>(json['role']),
      totalMessages: serializer.fromJson<int>(json['totalMessages']),
      unseenMessages: serializer.fromJson<int>(json['unseenMessages']),
      isSubscribed: serializer.fromJson<bool>(json['isSubscribed']),
      highestModSeq: serializer.fromJson<int?>(json['highestModSeq']),
      uidValidity: serializer.fromJson<int?>(json['uidValidity']),
      uidNext: serializer.fromJson<int?>(json['uidNext']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'accountId': serializer.toJson<String>(accountId),
      'role': serializer.toJson<String>(role),
      'totalMessages': serializer.toJson<int>(totalMessages),
      'unseenMessages': serializer.toJson<int>(unseenMessages),
      'isSubscribed': serializer.toJson<bool>(isSubscribed),
      'highestModSeq': serializer.toJson<int?>(highestModSeq),
      'uidValidity': serializer.toJson<int?>(uidValidity),
      'uidNext': serializer.toJson<int?>(uidNext),
    };
  }

  CachedMailboxe copyWith({
    String? path,
    String? name,
    String? accountId,
    String? role,
    int? totalMessages,
    int? unseenMessages,
    bool? isSubscribed,
    Value<int?> highestModSeq = const Value.absent(),
    Value<int?> uidValidity = const Value.absent(),
    Value<int?> uidNext = const Value.absent(),
  }) => CachedMailboxe(
    path: path ?? this.path,
    name: name ?? this.name,
    accountId: accountId ?? this.accountId,
    role: role ?? this.role,
    totalMessages: totalMessages ?? this.totalMessages,
    unseenMessages: unseenMessages ?? this.unseenMessages,
    isSubscribed: isSubscribed ?? this.isSubscribed,
    highestModSeq: highestModSeq.present
        ? highestModSeq.value
        : this.highestModSeq,
    uidValidity: uidValidity.present ? uidValidity.value : this.uidValidity,
    uidNext: uidNext.present ? uidNext.value : this.uidNext,
  );
  CachedMailboxe copyWithCompanion(CachedMailboxesCompanion data) {
    return CachedMailboxe(
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      role: data.role.present ? data.role.value : this.role,
      totalMessages: data.totalMessages.present
          ? data.totalMessages.value
          : this.totalMessages,
      unseenMessages: data.unseenMessages.present
          ? data.unseenMessages.value
          : this.unseenMessages,
      isSubscribed: data.isSubscribed.present
          ? data.isSubscribed.value
          : this.isSubscribed,
      highestModSeq: data.highestModSeq.present
          ? data.highestModSeq.value
          : this.highestModSeq,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
      uidNext: data.uidNext.present ? data.uidNext.value : this.uidNext,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMailboxe(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('accountId: $accountId, ')
          ..write('role: $role, ')
          ..write('totalMessages: $totalMessages, ')
          ..write('unseenMessages: $unseenMessages, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('highestModSeq: $highestModSeq, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('uidNext: $uidNext')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    path,
    name,
    accountId,
    role,
    totalMessages,
    unseenMessages,
    isSubscribed,
    highestModSeq,
    uidValidity,
    uidNext,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMailboxe &&
          other.path == this.path &&
          other.name == this.name &&
          other.accountId == this.accountId &&
          other.role == this.role &&
          other.totalMessages == this.totalMessages &&
          other.unseenMessages == this.unseenMessages &&
          other.isSubscribed == this.isSubscribed &&
          other.highestModSeq == this.highestModSeq &&
          other.uidValidity == this.uidValidity &&
          other.uidNext == this.uidNext);
}

class CachedMailboxesCompanion extends UpdateCompanion<CachedMailboxe> {
  final Value<String> path;
  final Value<String> name;
  final Value<String> accountId;
  final Value<String> role;
  final Value<int> totalMessages;
  final Value<int> unseenMessages;
  final Value<bool> isSubscribed;
  final Value<int?> highestModSeq;
  final Value<int?> uidValidity;
  final Value<int?> uidNext;
  final Value<int> rowid;
  const CachedMailboxesCompanion({
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.accountId = const Value.absent(),
    this.role = const Value.absent(),
    this.totalMessages = const Value.absent(),
    this.unseenMessages = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.highestModSeq = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.uidNext = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMailboxesCompanion.insert({
    required String path,
    required String name,
    required String accountId,
    this.role = const Value.absent(),
    this.totalMessages = const Value.absent(),
    this.unseenMessages = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.highestModSeq = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.uidNext = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       name = Value(name),
       accountId = Value(accountId);
  static Insertable<CachedMailboxe> custom({
    Expression<String>? path,
    Expression<String>? name,
    Expression<String>? accountId,
    Expression<String>? role,
    Expression<int>? totalMessages,
    Expression<int>? unseenMessages,
    Expression<bool>? isSubscribed,
    Expression<int>? highestModSeq,
    Expression<int>? uidValidity,
    Expression<int>? uidNext,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (accountId != null) 'account_id': accountId,
      if (role != null) 'role': role,
      if (totalMessages != null) 'total_messages': totalMessages,
      if (unseenMessages != null) 'unseen_messages': unseenMessages,
      if (isSubscribed != null) 'is_subscribed': isSubscribed,
      if (highestModSeq != null) 'highest_mod_seq': highestModSeq,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (uidNext != null) 'uid_next': uidNext,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMailboxesCompanion copyWith({
    Value<String>? path,
    Value<String>? name,
    Value<String>? accountId,
    Value<String>? role,
    Value<int>? totalMessages,
    Value<int>? unseenMessages,
    Value<bool>? isSubscribed,
    Value<int?>? highestModSeq,
    Value<int?>? uidValidity,
    Value<int?>? uidNext,
    Value<int>? rowid,
  }) {
    return CachedMailboxesCompanion(
      path: path ?? this.path,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      role: role ?? this.role,
      totalMessages: totalMessages ?? this.totalMessages,
      unseenMessages: unseenMessages ?? this.unseenMessages,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      highestModSeq: highestModSeq ?? this.highestModSeq,
      uidValidity: uidValidity ?? this.uidValidity,
      uidNext: uidNext ?? this.uidNext,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (totalMessages.present) {
      map['total_messages'] = Variable<int>(totalMessages.value);
    }
    if (unseenMessages.present) {
      map['unseen_messages'] = Variable<int>(unseenMessages.value);
    }
    if (isSubscribed.present) {
      map['is_subscribed'] = Variable<bool>(isSubscribed.value);
    }
    if (highestModSeq.present) {
      map['highest_mod_seq'] = Variable<int>(highestModSeq.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (uidNext.present) {
      map['uid_next'] = Variable<int>(uidNext.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMailboxesCompanion(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('accountId: $accountId, ')
          ..write('role: $role, ')
          ..write('totalMessages: $totalMessages, ')
          ..write('unseenMessages: $unseenMessages, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('highestModSeq: $highestModSeq, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('uidNext: $uidNext, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mailboxPathMeta = const VerificationMeta(
    'mailboxPath',
  );
  @override
  late final GeneratedColumn<String> mailboxPath = GeneratedColumn<String>(
    'mailbox_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedUidMeta = const VerificationMeta(
    'lastSyncedUid',
  );
  @override
  late final GeneratedColumn<int> lastSyncedUid = GeneratedColumn<int>(
    'last_synced_uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncTimeMeta = const VerificationMeta(
    'lastSyncTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncTime = GeneratedColumn<DateTime>(
    'last_sync_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    mailboxPath,
    lastSyncedUid,
    lastSyncTime,
    uidValidity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('mailbox_path')) {
      context.handle(
        _mailboxPathMeta,
        mailboxPath.isAcceptableOrUnknown(
          data['mailbox_path']!,
          _mailboxPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mailboxPathMeta);
    }
    if (data.containsKey('last_synced_uid')) {
      context.handle(
        _lastSyncedUidMeta,
        lastSyncedUid.isAcceptableOrUnknown(
          data['last_synced_uid']!,
          _lastSyncedUidMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_time')) {
      context.handle(
        _lastSyncTimeMeta,
        lastSyncTime.isAcceptableOrUnknown(
          data['last_sync_time']!,
          _lastSyncTimeMeta,
        ),
      );
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, mailboxPath};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mailboxPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mailbox_path'],
      )!,
      lastSyncedUid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_uid'],
      )!,
      lastSyncTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_time'],
      ),
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String accountId;
  final String mailboxPath;
  final int lastSyncedUid;
  final DateTime? lastSyncTime;
  final int? uidValidity;
  const SyncStateData({
    required this.accountId,
    required this.mailboxPath,
    required this.lastSyncedUid,
    this.lastSyncTime,
    this.uidValidity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['mailbox_path'] = Variable<String>(mailboxPath);
    map['last_synced_uid'] = Variable<int>(lastSyncedUid);
    if (!nullToAbsent || lastSyncTime != null) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime);
    }
    if (!nullToAbsent || uidValidity != null) {
      map['uid_validity'] = Variable<int>(uidValidity);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      accountId: Value(accountId),
      mailboxPath: Value(mailboxPath),
      lastSyncedUid: Value(lastSyncedUid),
      lastSyncTime: lastSyncTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncTime),
      uidValidity: uidValidity == null && nullToAbsent
          ? const Value.absent()
          : Value(uidValidity),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      accountId: serializer.fromJson<String>(json['accountId']),
      mailboxPath: serializer.fromJson<String>(json['mailboxPath']),
      lastSyncedUid: serializer.fromJson<int>(json['lastSyncedUid']),
      lastSyncTime: serializer.fromJson<DateTime?>(json['lastSyncTime']),
      uidValidity: serializer.fromJson<int?>(json['uidValidity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'mailboxPath': serializer.toJson<String>(mailboxPath),
      'lastSyncedUid': serializer.toJson<int>(lastSyncedUid),
      'lastSyncTime': serializer.toJson<DateTime?>(lastSyncTime),
      'uidValidity': serializer.toJson<int?>(uidValidity),
    };
  }

  SyncStateData copyWith({
    String? accountId,
    String? mailboxPath,
    int? lastSyncedUid,
    Value<DateTime?> lastSyncTime = const Value.absent(),
    Value<int?> uidValidity = const Value.absent(),
  }) => SyncStateData(
    accountId: accountId ?? this.accountId,
    mailboxPath: mailboxPath ?? this.mailboxPath,
    lastSyncedUid: lastSyncedUid ?? this.lastSyncedUid,
    lastSyncTime: lastSyncTime.present ? lastSyncTime.value : this.lastSyncTime,
    uidValidity: uidValidity.present ? uidValidity.value : this.uidValidity,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mailboxPath: data.mailboxPath.present
          ? data.mailboxPath.value
          : this.mailboxPath,
      lastSyncedUid: data.lastSyncedUid.present
          ? data.lastSyncedUid.value
          : this.lastSyncedUid,
      lastSyncTime: data.lastSyncTime.present
          ? data.lastSyncTime.value
          : this.lastSyncTime,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('accountId: $accountId, ')
          ..write('mailboxPath: $mailboxPath, ')
          ..write('lastSyncedUid: $lastSyncedUid, ')
          ..write('lastSyncTime: $lastSyncTime, ')
          ..write('uidValidity: $uidValidity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    mailboxPath,
    lastSyncedUid,
    lastSyncTime,
    uidValidity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.accountId == this.accountId &&
          other.mailboxPath == this.mailboxPath &&
          other.lastSyncedUid == this.lastSyncedUid &&
          other.lastSyncTime == this.lastSyncTime &&
          other.uidValidity == this.uidValidity);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> accountId;
  final Value<String> mailboxPath;
  final Value<int> lastSyncedUid;
  final Value<DateTime?> lastSyncTime;
  final Value<int?> uidValidity;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.accountId = const Value.absent(),
    this.mailboxPath = const Value.absent(),
    this.lastSyncedUid = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String accountId,
    required String mailboxPath,
    this.lastSyncedUid = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       mailboxPath = Value(mailboxPath);
  static Insertable<SyncStateData> custom({
    Expression<String>? accountId,
    Expression<String>? mailboxPath,
    Expression<int>? lastSyncedUid,
    Expression<DateTime>? lastSyncTime,
    Expression<int>? uidValidity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (mailboxPath != null) 'mailbox_path': mailboxPath,
      if (lastSyncedUid != null) 'last_synced_uid': lastSyncedUid,
      if (lastSyncTime != null) 'last_sync_time': lastSyncTime,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? accountId,
    Value<String>? mailboxPath,
    Value<int>? lastSyncedUid,
    Value<DateTime?>? lastSyncTime,
    Value<int?>? uidValidity,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      accountId: accountId ?? this.accountId,
      mailboxPath: mailboxPath ?? this.mailboxPath,
      lastSyncedUid: lastSyncedUid ?? this.lastSyncedUid,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      uidValidity: uidValidity ?? this.uidValidity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mailboxPath.present) {
      map['mailbox_path'] = Variable<String>(mailboxPath.value);
    }
    if (lastSyncedUid.present) {
      map['last_synced_uid'] = Variable<int>(lastSyncedUid.value);
    }
    if (lastSyncTime.present) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('accountId: $accountId, ')
          ..write('mailboxPath: $mailboxPath, ')
          ..write('lastSyncedUid: $lastSyncedUid, ')
          ..write('lastSyncTime: $lastSyncTime, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CrusaderDatabase extends GeneratedDatabase {
  _$CrusaderDatabase(QueryExecutor e) : super(e);
  $CrusaderDatabaseManager get managers => $CrusaderDatabaseManager(this);
  late final $CachedEmailsTable cachedEmails = $CachedEmailsTable(this);
  late final $CachedMailboxesTable cachedMailboxes = $CachedMailboxesTable(
    this,
  );
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedEmails,
    cachedMailboxes,
    syncState,
  ];
}

typedef $$CachedEmailsTableCreateCompanionBuilder =
    CachedEmailsCompanion Function({
      required String id,
      required String accountId,
      required String mailboxPath,
      required int uid,
      required String fromAddress,
      Value<String?> fromName,
      required String toAddresses,
      Value<String> ccAddresses,
      Value<String> subject,
      required DateTime date,
      Value<String?> textPlain,
      Value<String?> textHtml,
      Value<String> snippet,
      Value<String> flags,
      Value<String?> messageId,
      Value<String?> inReplyTo,
      Value<String> references,
      Value<String?> threadId,
      Value<int> size,
      Value<bool> hasAttachments,
      Value<int> attachmentCount,
      Value<String> attachmentsJson,
      Value<DateTime?> snoozedUntil,
      Value<bool> isSnoozed,
      Value<int> rowid,
    });
typedef $$CachedEmailsTableUpdateCompanionBuilder =
    CachedEmailsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> mailboxPath,
      Value<int> uid,
      Value<String> fromAddress,
      Value<String?> fromName,
      Value<String> toAddresses,
      Value<String> ccAddresses,
      Value<String> subject,
      Value<DateTime> date,
      Value<String?> textPlain,
      Value<String?> textHtml,
      Value<String> snippet,
      Value<String> flags,
      Value<String?> messageId,
      Value<String?> inReplyTo,
      Value<String> references,
      Value<String?> threadId,
      Value<int> size,
      Value<bool> hasAttachments,
      Value<int> attachmentCount,
      Value<String> attachmentsJson,
      Value<DateTime?> snoozedUntil,
      Value<bool> isSnoozed,
      Value<int> rowid,
    });

class $$CachedEmailsTableFilterComposer
    extends Composer<_$CrusaderDatabase, $CachedEmailsTable> {
  $$CachedEmailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAddresses => $composableBuilder(
    column: $table.toAddresses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ccAddresses => $composableBuilder(
    column: $table.ccAddresses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textPlain => $composableBuilder(
    column: $table.textPlain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textHtml => $composableBuilder(
    column: $table.textHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get references => $composableBuilder(
    column: $table.references,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attachmentCount => $composableBuilder(
    column: $table.attachmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSnoozed => $composableBuilder(
    column: $table.isSnoozed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedEmailsTableOrderingComposer
    extends Composer<_$CrusaderDatabase, $CachedEmailsTable> {
  $$CachedEmailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAddresses => $composableBuilder(
    column: $table.toAddresses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ccAddresses => $composableBuilder(
    column: $table.ccAddresses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textPlain => $composableBuilder(
    column: $table.textPlain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textHtml => $composableBuilder(
    column: $table.textHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get references => $composableBuilder(
    column: $table.references,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attachmentCount => $composableBuilder(
    column: $table.attachmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSnoozed => $composableBuilder(
    column: $table.isSnoozed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedEmailsTableAnnotationComposer
    extends Composer<_$CrusaderDatabase, $CachedEmailsTable> {
  $$CachedEmailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromName =>
      $composableBuilder(column: $table.fromName, builder: (column) => column);

  GeneratedColumn<String> get toAddresses => $composableBuilder(
    column: $table.toAddresses,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ccAddresses => $composableBuilder(
    column: $table.ccAddresses,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get textPlain =>
      $composableBuilder(column: $table.textPlain, builder: (column) => column);

  GeneratedColumn<String> get textHtml =>
      $composableBuilder(column: $table.textHtml, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<String> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get inReplyTo =>
      $composableBuilder(column: $table.inReplyTo, builder: (column) => column);

  GeneratedColumn<String> get references => $composableBuilder(
    column: $table.references,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attachmentCount => $composableBuilder(
    column: $table.attachmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSnoozed =>
      $composableBuilder(column: $table.isSnoozed, builder: (column) => column);
}

class $$CachedEmailsTableTableManager
    extends
        RootTableManager<
          _$CrusaderDatabase,
          $CachedEmailsTable,
          CachedEmail,
          $$CachedEmailsTableFilterComposer,
          $$CachedEmailsTableOrderingComposer,
          $$CachedEmailsTableAnnotationComposer,
          $$CachedEmailsTableCreateCompanionBuilder,
          $$CachedEmailsTableUpdateCompanionBuilder,
          (
            CachedEmail,
            BaseReferences<_$CrusaderDatabase, $CachedEmailsTable, CachedEmail>,
          ),
          CachedEmail,
          PrefetchHooks Function()
        > {
  $$CachedEmailsTableTableManager(
    _$CrusaderDatabase db,
    $CachedEmailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEmailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEmailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEmailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> mailboxPath = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String> fromAddress = const Value.absent(),
                Value<String?> fromName = const Value.absent(),
                Value<String> toAddresses = const Value.absent(),
                Value<String> ccAddresses = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> textPlain = const Value.absent(),
                Value<String?> textHtml = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> flags = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String> references = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<int> attachmentCount = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<bool> isSnoozed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEmailsCompanion(
                id: id,
                accountId: accountId,
                mailboxPath: mailboxPath,
                uid: uid,
                fromAddress: fromAddress,
                fromName: fromName,
                toAddresses: toAddresses,
                ccAddresses: ccAddresses,
                subject: subject,
                date: date,
                textPlain: textPlain,
                textHtml: textHtml,
                snippet: snippet,
                flags: flags,
                messageId: messageId,
                inReplyTo: inReplyTo,
                references: references,
                threadId: threadId,
                size: size,
                hasAttachments: hasAttachments,
                attachmentCount: attachmentCount,
                attachmentsJson: attachmentsJson,
                snoozedUntil: snoozedUntil,
                isSnoozed: isSnoozed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String mailboxPath,
                required int uid,
                required String fromAddress,
                Value<String?> fromName = const Value.absent(),
                required String toAddresses,
                Value<String> ccAddresses = const Value.absent(),
                Value<String> subject = const Value.absent(),
                required DateTime date,
                Value<String?> textPlain = const Value.absent(),
                Value<String?> textHtml = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> flags = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String> references = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<int> attachmentCount = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<bool> isSnoozed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEmailsCompanion.insert(
                id: id,
                accountId: accountId,
                mailboxPath: mailboxPath,
                uid: uid,
                fromAddress: fromAddress,
                fromName: fromName,
                toAddresses: toAddresses,
                ccAddresses: ccAddresses,
                subject: subject,
                date: date,
                textPlain: textPlain,
                textHtml: textHtml,
                snippet: snippet,
                flags: flags,
                messageId: messageId,
                inReplyTo: inReplyTo,
                references: references,
                threadId: threadId,
                size: size,
                hasAttachments: hasAttachments,
                attachmentCount: attachmentCount,
                attachmentsJson: attachmentsJson,
                snoozedUntil: snoozedUntil,
                isSnoozed: isSnoozed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedEmailsTableProcessedTableManager =
    ProcessedTableManager<
      _$CrusaderDatabase,
      $CachedEmailsTable,
      CachedEmail,
      $$CachedEmailsTableFilterComposer,
      $$CachedEmailsTableOrderingComposer,
      $$CachedEmailsTableAnnotationComposer,
      $$CachedEmailsTableCreateCompanionBuilder,
      $$CachedEmailsTableUpdateCompanionBuilder,
      (
        CachedEmail,
        BaseReferences<_$CrusaderDatabase, $CachedEmailsTable, CachedEmail>,
      ),
      CachedEmail,
      PrefetchHooks Function()
    >;
typedef $$CachedMailboxesTableCreateCompanionBuilder =
    CachedMailboxesCompanion Function({
      required String path,
      required String name,
      required String accountId,
      Value<String> role,
      Value<int> totalMessages,
      Value<int> unseenMessages,
      Value<bool> isSubscribed,
      Value<int?> highestModSeq,
      Value<int?> uidValidity,
      Value<int?> uidNext,
      Value<int> rowid,
    });
typedef $$CachedMailboxesTableUpdateCompanionBuilder =
    CachedMailboxesCompanion Function({
      Value<String> path,
      Value<String> name,
      Value<String> accountId,
      Value<String> role,
      Value<int> totalMessages,
      Value<int> unseenMessages,
      Value<bool> isSubscribed,
      Value<int?> highestModSeq,
      Value<int?> uidValidity,
      Value<int?> uidNext,
      Value<int> rowid,
    });

class $$CachedMailboxesTableFilterComposer
    extends Composer<_$CrusaderDatabase, $CachedMailboxesTable> {
  $$CachedMailboxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMessages => $composableBuilder(
    column: $table.totalMessages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unseenMessages => $composableBuilder(
    column: $table.unseenMessages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidNext => $composableBuilder(
    column: $table.uidNext,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMailboxesTableOrderingComposer
    extends Composer<_$CrusaderDatabase, $CachedMailboxesTable> {
  $$CachedMailboxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMessages => $composableBuilder(
    column: $table.totalMessages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unseenMessages => $composableBuilder(
    column: $table.unseenMessages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidNext => $composableBuilder(
    column: $table.uidNext,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMailboxesTableAnnotationComposer
    extends Composer<_$CrusaderDatabase, $CachedMailboxesTable> {
  $$CachedMailboxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get totalMessages => $composableBuilder(
    column: $table.totalMessages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unseenMessages => $composableBuilder(
    column: $table.unseenMessages,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uidNext =>
      $composableBuilder(column: $table.uidNext, builder: (column) => column);
}

class $$CachedMailboxesTableTableManager
    extends
        RootTableManager<
          _$CrusaderDatabase,
          $CachedMailboxesTable,
          CachedMailboxe,
          $$CachedMailboxesTableFilterComposer,
          $$CachedMailboxesTableOrderingComposer,
          $$CachedMailboxesTableAnnotationComposer,
          $$CachedMailboxesTableCreateCompanionBuilder,
          $$CachedMailboxesTableUpdateCompanionBuilder,
          (
            CachedMailboxe,
            BaseReferences<
              _$CrusaderDatabase,
              $CachedMailboxesTable,
              CachedMailboxe
            >,
          ),
          CachedMailboxe,
          PrefetchHooks Function()
        > {
  $$CachedMailboxesTableTableManager(
    _$CrusaderDatabase db,
    $CachedMailboxesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMailboxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMailboxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMailboxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> totalMessages = const Value.absent(),
                Value<int> unseenMessages = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<int?> highestModSeq = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int?> uidNext = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMailboxesCompanion(
                path: path,
                name: name,
                accountId: accountId,
                role: role,
                totalMessages: totalMessages,
                unseenMessages: unseenMessages,
                isSubscribed: isSubscribed,
                highestModSeq: highestModSeq,
                uidValidity: uidValidity,
                uidNext: uidNext,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String name,
                required String accountId,
                Value<String> role = const Value.absent(),
                Value<int> totalMessages = const Value.absent(),
                Value<int> unseenMessages = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<int?> highestModSeq = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int?> uidNext = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMailboxesCompanion.insert(
                path: path,
                name: name,
                accountId: accountId,
                role: role,
                totalMessages: totalMessages,
                unseenMessages: unseenMessages,
                isSubscribed: isSubscribed,
                highestModSeq: highestModSeq,
                uidValidity: uidValidity,
                uidNext: uidNext,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMailboxesTableProcessedTableManager =
    ProcessedTableManager<
      _$CrusaderDatabase,
      $CachedMailboxesTable,
      CachedMailboxe,
      $$CachedMailboxesTableFilterComposer,
      $$CachedMailboxesTableOrderingComposer,
      $$CachedMailboxesTableAnnotationComposer,
      $$CachedMailboxesTableCreateCompanionBuilder,
      $$CachedMailboxesTableUpdateCompanionBuilder,
      (
        CachedMailboxe,
        BaseReferences<
          _$CrusaderDatabase,
          $CachedMailboxesTable,
          CachedMailboxe
        >,
      ),
      CachedMailboxe,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String accountId,
      required String mailboxPath,
      Value<int> lastSyncedUid,
      Value<DateTime?> lastSyncTime,
      Value<int?> uidValidity,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> accountId,
      Value<String> mailboxPath,
      Value<int> lastSyncedUid,
      Value<DateTime?> lastSyncTime,
      Value<int?> uidValidity,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$CrusaderDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedUid => $composableBuilder(
    column: $table.lastSyncedUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$CrusaderDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedUid => $composableBuilder(
    column: $table.lastSyncedUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$CrusaderDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mailboxPath => $composableBuilder(
    column: $table.mailboxPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedUid => $composableBuilder(
    column: $table.lastSyncedUid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncTime => $composableBuilder(
    column: $table.lastSyncTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$CrusaderDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$CrusaderDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$CrusaderDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> mailboxPath = const Value.absent(),
                Value<int> lastSyncedUid = const Value.absent(),
                Value<DateTime?> lastSyncTime = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                accountId: accountId,
                mailboxPath: mailboxPath,
                lastSyncedUid: lastSyncedUid,
                lastSyncTime: lastSyncTime,
                uidValidity: uidValidity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String mailboxPath,
                Value<int> lastSyncedUid = const Value.absent(),
                Value<DateTime?> lastSyncTime = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                accountId: accountId,
                mailboxPath: mailboxPath,
                lastSyncedUid: lastSyncedUid,
                lastSyncTime: lastSyncTime,
                uidValidity: uidValidity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$CrusaderDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$CrusaderDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;

class $CrusaderDatabaseManager {
  final _$CrusaderDatabase _db;
  $CrusaderDatabaseManager(this._db);
  $$CachedEmailsTableTableManager get cachedEmails =>
      $$CachedEmailsTableTableManager(_db, _db.cachedEmails);
  $$CachedMailboxesTableTableManager get cachedMailboxes =>
      $$CachedMailboxesTableTableManager(_db, _db.cachedMailboxes);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
