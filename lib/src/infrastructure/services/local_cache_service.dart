import 'dart:convert';
import 'package:hive/hive.dart';

/// Generic local cache service backed by Hive.
/// Stores JSON-serializable data keyed by collection + document ID.
/// Used as an offline-first layer between repositories and Firestore.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._();
  static LocalCacheService get instance => _instance;
  LocalCacheService._();

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>('quantum_cache');
  }

  /// Store a single document by [collection] and [docId].
  /// [data] must be JSON-encodable (Map<String, dynamic>).
  Future<void> put(String collection, String docId, Map<String, dynamic> data) async {
    final key = '$collection:$docId';
    await _box.put(key, jsonEncode(data));
  }

  /// Retrieve a single cached document, or null if not found.
  Map<String, dynamic>? get(String collection, String docId) {
    final key = '$collection:$docId';
    final raw = _box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Store a full collection snapshot as a list of documents.
  Future<void> putCollection(String collection, List<Map<String, dynamic>> items) async {
    final key = 'collection:$collection';
    await _box.put(key, jsonEncode(items));
  }

  /// Retrieve a cached collection snapshot, or null if not found.
  List<Map<String, dynamic>>? getCollection(String collection) {
    final key = 'collection:$collection';
    final raw = _box.get(key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Store the last sync timestamp for a collection.
  Future<void> setLastSync(String collection, DateTime timestamp) async {
    final key = 'sync:$collection';
    await _box.put(key, timestamp.toIso8601String());
  }

  /// Get the last sync timestamp for a collection, or null if never synced.
  DateTime? getLastSync(String collection) {
    final key = 'sync:$collection';
    final raw = _box.get(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Check if a collection has been cached.
  bool hasCollection(String collection) {
    final key = 'collection:$collection';
    return _box.containsKey(key);
  }

  /// Clear all cached data for a specific collection.
  Future<void> clearCollection(String collection) async {
    final keys = _box.keys.where((k) {
      final str = k.toString();
      return str.startsWith('$collection:') ||
          str.startsWith('collection:$collection') ||
          str.startsWith('sync:$collection');
    });
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Clear all cached data.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
