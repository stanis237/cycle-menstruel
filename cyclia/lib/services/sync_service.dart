import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _lastKey = 'last_cloud_sync';

  Future<void> updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_lastKey, now.toIso8601String());
  }

  Future<String> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastKey);
    if (lastSyncStr == null) return "Jamais";
    
    final lastSync = DateTime.parse(lastSyncStr);
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) return "À l'instant";
    if (difference.inMinutes < 60) return "Il y a ${difference.inMinutes} min";
    if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
    
    return DateFormat('dd/MM/yyyy HH:mm').format(lastSync);
  }
}
