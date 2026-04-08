/// Crusader — Email Address Entity
///
/// Represents a single email address with optional display name.
library;

/// Immutable email address value object.
class EmailAddress {
  const EmailAddress({
    required this.address,
    this.displayName,
  });

  final String address;
  final String? displayName;

  /// Display-friendly label: "Name \<addr\>" or just "addr".
  String get label => displayName != null && displayName!.isNotEmpty
      ? '$displayName <$address>'
      : address;

  /// Short label: display name if available, otherwise address.
  String get shortLabel => displayName ?? address;

  /// First letter for avatar placeholders.
  String get initial =>
      (displayName?.isNotEmpty == true ? displayName! : address)
          .substring(0, 1)
          .toUpperCase();

  Map<String, dynamic> toJson() => {
        'address': address,
        'displayName': displayName,
      };

  factory EmailAddress.fromJson(Map<String, dynamic> json) => EmailAddress(
        address: json['address'] as String,
        displayName: json['displayName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAddress &&
          runtimeType == other.runtimeType &&
          address.toLowerCase() == other.address.toLowerCase();

  @override
  int get hashCode => address.toLowerCase().hashCode;

  @override
  String toString() => label;
}
