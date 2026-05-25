import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/models/models.dart';

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

class CacheService {
  static const _profileKey = 'cache_profile';
  static const _avatarKey = 'cache_avatar';
  static const _summaryKey = 'cache_summary';
  static const _summaryDateKey = 'cache_summary_date';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAvatar(Avatar avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, jsonEncode(avatar.toJson()));
  }

  Future<Avatar?> loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_avatarKey);
    if (raw == null) return null;
    return Avatar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSummary(RecordSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryKey, jsonEncode(summary.toJson()));
    await prefs.setString(_summaryDateKey, summary.date);
  }

  Future<RecordSummary?> loadSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_summaryDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (date != today) return null; // 日付が変わったら無効
    final raw = prefs.getString(_summaryKey);
    if (raw == null) return null;
    return RecordSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_avatarKey);
    await prefs.remove(_summaryKey);
    await prefs.remove(_summaryDateKey);
  }
}
