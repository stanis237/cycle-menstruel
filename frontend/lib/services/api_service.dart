import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch complete user profile info
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  // Update profile and onboarding details
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/'),
        headers: headers,
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  // Fetch all cycles
  Future<List<dynamic>?> getCycles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cycles/'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get cycles error: $e');
      return null;
    }
  }

  // Create a new cycle starting on start_date (YYYY-MM-DD)
  Future<Map<String, dynamic>?> startCycle(String startDate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cycles/start-or-update/'),
        headers: headers,
        body: jsonEncode({'start_date': startDate}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Start cycle error: $e');
      return null;
    }
  }

  // Get daily entry for a specific date (YYYY-MM-DD)
  Future<Map<String, dynamic>?> getDailyEntry(String date) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/daily-entries/by-date/?date=$date'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.trim().isEmpty || body == '{}') {
          return null;
        }
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('Get daily entry error: $e');
      return null;
    }
  }

  // Fetch all daily entries
  Future<List<dynamic>?> getDailyEntries() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/daily-entries/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('Get all daily entries error: $e');
      return null;
    }
  }

  // Save daily entry (symptoms)
  Future<bool> saveDailyEntry(Map<String, dynamic> entryData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/daily-entries/by-date/'),
        headers: headers,
        body: jsonEncode(entryData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Save daily entry error: $e');
      return false;
    }
  }

  // Fetch predictions and status of current cycle
  Future<Map<String, dynamic>?> getPredictions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/predictions/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('Get predictions error: $e');
      return null;
    }
  }
}
