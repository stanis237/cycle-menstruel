import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // For mobile platforms, use conditional import or default to localhost
    // Android emulator uses 10.0.2.2 to reach host machine
    // For now, use localhost as default (works for iOS simulator and desktop)
    return 'http://10.0.2.2:8000/api';
  }
}
