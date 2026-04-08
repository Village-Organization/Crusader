/// Crusader — Avatar Service
///
/// Fetches Gravatar images by MD5-hashing email addresses.
/// Caches downloaded avatars to disk for offline/fast display.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// In-memory + disk-cached Gravatar resolver.
///
/// Usage:
/// ```dart
/// final bytes = await AvatarService.instance.getAvatar('user@example.com');
/// ```
class AvatarService {
  AvatarService._();

  static final AvatarService instance = AvatarService._();

  /// In-memory LRU-ish cache (email → bytes or `null` for 404).
  final Map<String, Uint8List?> _memCache = {};

  /// Emails currently being fetched — dedup parallel requests.
  final Map<String, Future<Uint8List?>> _inflight = {};

  /// Set of emails known to have no Gravatar (404).
  final Set<String> _misses = {};

  /// Max entries in memory cache before evicting oldest.
  static const int _maxMemEntries = 200;

  /// Gravatar image size in pixels.
  static const int _size = 80;

  Directory? _cacheDir;

  /// Lazily resolve the on-disk cache directory.
  Future<Directory> get _diskCacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'avatar_cache'));
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
    return _cacheDir!;
  }

  /// Compute the MD5 hash of a lowercased, trimmed email.
  String _emailHash(String email) {
    final normalized = email.trim().toLowerCase();
    return md5.convert(normalized.codeUnits).toString();
  }

  /// Get avatar bytes for [email], or `null` if none exists.
  ///
  /// Resolution order: memory → disk → network.
  /// Results are cached at every layer.
  Future<Uint8List?> getAvatar(String email) async {
    final hash = _emailHash(email);

    // 1. Memory cache hit.
    if (_memCache.containsKey(hash)) return _memCache[hash];
    if (_misses.contains(hash)) return null;

    // 2. Dedup — if already fetching, await the same future.
    if (_inflight.containsKey(hash)) return _inflight[hash];

    final future = _resolve(hash);
    _inflight[hash] = future;
    try {
      final result = await future;
      return result;
    } finally {
      _inflight.remove(hash);
    }
  }

  Future<Uint8List?> _resolve(String hash) async {
    // 2. Disk cache.
    final dir = await _diskCacheDir;
    final file = File(p.join(dir.path, '$hash.png'));
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      _putMem(hash, bytes);
      return bytes;
    }

    // 3. Network fetch.
    try {
      final url = Uri.parse(
        'https://www.gravatar.com/avatar/$hash'
        '?s=$_size&d=404&r=g',
      );
      final response = await http.get(url).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty &&
          (response.headers['content-type']?.contains('image') ?? false)) {
        final bytes = response.bodyBytes;
        // Write to disk (fire-and-forget).
        file.writeAsBytes(bytes).ignore();
        _putMem(hash, bytes);
        return bytes;
      }

      // 404 or unexpected — mark as miss.
      _misses.add(hash);
      _putMem(hash, null);
      return null;
    } catch (_) {
      // Network error — don't cache the miss permanently,
      // just return null so we retry next time.
      return null;
    }
  }

  void _putMem(String hash, Uint8List? bytes) {
    // Evict oldest if over limit.
    if (_memCache.length >= _maxMemEntries) {
      _memCache.remove(_memCache.keys.first);
    }
    _memCache[hash] = bytes;
  }

  /// Pre-warm cache for a batch of emails (e.g. on inbox load).
  /// Fires off parallel fetches with concurrency limit.
  Future<void> prefetch(Iterable<String> emails) async {
    final unique = emails.toSet();
    final toFetch = <String>[];
    for (final email in unique) {
      final hash = _emailHash(email);
      if (!_memCache.containsKey(hash) && !_misses.contains(hash)) {
        toFetch.add(email);
      }
    }
    if (toFetch.isEmpty) return;

    // Fetch up to 6 at a time.
    const batchSize = 6;
    for (var i = 0; i < toFetch.length; i += batchSize) {
      final batch = toFetch.skip(i).take(batchSize);
      await Future.wait(batch.map(getAvatar));
    }
  }

  /// Clear all caches (memory + disk).
  Future<void> clearCache() async {
    _memCache.clear();
    _misses.clear();
    final dir = await _diskCacheDir;
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
    }
  }
}
