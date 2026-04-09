/// Crusader — Email Account Entity
///
/// Domain-level representation of a connected email account.
library;

/// Supported email providers.
enum EmailProvider { gmail, outlook, custom }

/// How the account authenticates with the mail server.
enum AuthMethod { oauth2, password }

/// Immutable entity representing a connected email account.
class EmailAccount {
  const EmailAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    this.authMethod = AuthMethod.oauth2,
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String email;
  final String displayName;
  final EmailProvider provider;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final AuthMethod authMethod;
  final String? avatarUrl;
  final bool isActive;

  /// IMAP/SMTP server configs per provider.
  static EmailAccount fromProvider({
    required String id,
    required String email,
    required String displayName,
    required EmailProvider provider,
    String? avatarUrl,
  }) {
    switch (provider) {
      case EmailProvider.gmail:
        return EmailAccount(
          id: id,
          email: email,
          displayName: displayName,
          provider: provider,
          imapHost: 'imap.gmail.com',
          imapPort: 993,
          smtpHost: 'smtp.gmail.com',
          smtpPort: 465,
          authMethod: AuthMethod.oauth2,
          avatarUrl: avatarUrl,
        );
      case EmailProvider.outlook:
        return EmailAccount(
          id: id,
          email: email,
          displayName: displayName,
          provider: provider,
          imapHost: 'outlook.office365.com',
          imapPort: 993,
          smtpHost: 'smtp.office365.com',
          smtpPort: 587,
          authMethod: AuthMethod.oauth2,
          avatarUrl: avatarUrl,
        );
      case EmailProvider.custom:
        throw ArgumentError('Use the direct constructor for custom providers.');
    }
  }

  EmailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    EmailProvider? provider,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    AuthMethod? authMethod,
    String? avatarUrl,
    bool? isActive,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      authMethod: authMethod ?? this.authMethod,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'provider': provider.name,
    'imapHost': imapHost,
    'imapPort': imapPort,
    'smtpHost': smtpHost,
    'smtpPort': smtpPort,
    'authMethod': authMethod.name,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
  };

  factory EmailAccount.fromJson(Map<String, dynamic> json) => EmailAccount(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    provider: EmailProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => EmailProvider.custom,
    ),
    imapHost: json['imapHost'] as String,
    imapPort: json['imapPort'] as int,
    smtpHost: json['smtpHost'] as String,
    smtpPort: json['smtpPort'] as int,
    authMethod: AuthMethod.values.firstWhere(
      (a) => a.name == json['authMethod'],
      orElse: () => AuthMethod.oauth2,
    ),
    avatarUrl: json['avatarUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmailAccount($email, $provider, $authMethod)';
}
