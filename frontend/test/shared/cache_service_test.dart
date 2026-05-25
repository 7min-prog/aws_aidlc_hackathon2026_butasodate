import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/services/cache_service.dart';
import 'package:buta_app/shared/models/models.dart';

void main() {
  late CacheService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = CacheService();
  });

  group('CacheService profile', () {
    test('saveProfile and loadProfile round-trip', () async {
      final profile = UserProfile(userId: 'u1', email: 'a@b.com', nickname: 'テスト', authProvider: 'EMAIL', createdAt: '2026-01-01');
      await service.saveProfile(profile);
      final loaded = await service.loadProfile();
      expect(loaded, isNotNull);
      expect(loaded!.userId, 'u1');
      expect(loaded.nickname, 'テスト');
    });

    test('loadProfile returns null when empty', () async {
      final loaded = await service.loadProfile();
      expect(loaded, isNull);
    });
  });

  group('CacheService avatar', () {
    test('saveAvatar and loadAvatar round-trip', () async {
      final avatar = Avatar(avatarId: 'a1', userId: 'u1', name: 'ぶた', totalPoints: 100, level: 2, evolutionStage: 1, stats: AvatarStats(hp: 10, attack: 5, defense: 3, speed: 2), skillIds: ['s1'], spriteSheetKey: 'sprites/stage1/default');
      await service.saveAvatar(avatar);
      final loaded = await service.loadAvatar();
      expect(loaded, isNotNull);
      expect(loaded!.avatarId, 'a1');
      expect(loaded.name, 'ぶた');
      expect(loaded.stats.hp, 10);
    });

    test('loadAvatar returns null when empty', () async {
      final loaded = await service.loadAvatar();
      expect(loaded, isNull);
    });
  });

  group('CacheService summary', () {
    test('saveSummary and loadSummary round-trip (today)', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final summary = RecordSummary(todayCount: 3, todayPoints: 150, date: today);
      await service.saveSummary(summary);
      final loaded = await service.loadSummary();
      expect(loaded, isNotNull);
      expect(loaded!.todayCount, 3);
      expect(loaded.todayPoints, 150);
    });

    test('loadSummary returns null for old date', () async {
      final summary = RecordSummary(todayCount: 1, todayPoints: 50, date: '2020-01-01');
      await service.saveSummary(summary);
      final loaded = await service.loadSummary();
      expect(loaded, isNull);
    });

    test('loadSummary returns null when empty', () async {
      final loaded = await service.loadSummary();
      expect(loaded, isNull);
    });
  });

  group('CacheService clearAll', () {
    test('clearAll removes all cached data', () async {
      final profile = UserProfile(userId: 'u1', email: 'a@b.com', nickname: 'n', authProvider: 'EMAIL', createdAt: '2026-01-01');
      await service.saveProfile(profile);
      await service.clearAll();
      expect(await service.loadProfile(), isNull);
      expect(await service.loadAvatar(), isNull);
      expect(await service.loadSummary(), isNull);
    });
  });
}
