/// Crusader — Attachment Entity
///
/// Represents an email attachment (file, inline image, etc.).
/// Immutable, serializable, provider-agnostic.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Immutable attachment domain entity.
class Attachment {
  const Attachment({
    required this.filename,
    required this.mimeType,
    this.size = 0,
    this.contentId,
    this.isInline = false,
    this.data,
  });

  /// Original filename (e.g. "report.pdf").
  final String filename;

  /// MIME type (e.g. "application/pdf", "image/png").
  final String mimeType;

  /// File size in bytes.
  final int size;

  /// Content-ID for inline attachments (used in HTML body references).
  final String? contentId;

  /// Whether this is an inline attachment (e.g. embedded image).
  final bool isInline;

  /// Raw binary data (only populated after full fetch).
  final Uint8List? data;

  // ── Convenience getters ──

  /// File extension from the filename.
  String get extension {
    final dot = filename.lastIndexOf('.');
    return dot >= 0 ? filename.substring(dot + 1).toLowerCase() : '';
  }

  /// Whether this is an image attachment.
  bool get isImage => mimeType.startsWith('image/');

  /// Whether this is a PDF attachment.
  bool get isPdf => mimeType == 'application/pdf';

  /// Human-readable file size.
  String get humanSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Serialization (for JSON storage in Drift) ──

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'mimeType': mimeType,
        'size': size,
        if (contentId != null) 'contentId': contentId,
        'isInline': isInline,
        // Don't serialize binary data to JSON — too large.
        // Data is fetched on-demand when needed.
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        filename: json['filename'] as String? ?? 'unknown',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        size: json['size'] as int? ?? 0,
        contentId: json['contentId'] as String?,
        isInline: json['isInline'] as bool? ?? false,
      );

  /// Encode a list of attachments to a JSON string for DB storage.
  static String encodeList(List<Attachment> attachments) {
    if (attachments.isEmpty) return '[]';
    return jsonEncode(attachments.map((a) => a.toJson()).toList());
  }

  /// Decode a JSON string back to a list of attachments.
  static List<Attachment> decodeList(String? json) {
    if (json == null || json.isEmpty || json == '[]') return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((j) => Attachment.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toString() => 'Attachment($filename, $humanSize)';
}
