import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/models/models.dart';

void main() {
  group('UserProfile', () {
    test('fromJson全フィールド', () {
      final p = UserProfile.fromJson({'userId': 'u1', 'nickname': 'test', 'email': 'a@b.com', 'authProvider': 'GOOGLE', 'createdAt': '2026-01-01'});
      expect(p.userId, 'u1');
      expect(p.nickname, 'test');
      expect(p.hasNickname, true);
    });

    test('fromJson nickname null', () {
      final p = UserProfile.fromJson({'userId': 'u1'});
      expect(p.nickname, isNull);
      expect(p.hasNickname, false);
    });

    test('hasNickname空文字はfalse', () {
      final p = UserProfile(userId: 'u1', nickname: '', email: '', authProvider: '', createdAt: '');
      expect(p.hasNickname, false);
    });

    test('toJson', () {
      final p = UserProfile(userId: 'u1', nickname: 'n', email: 'e', authProvider: 'EMAIL', createdAt: 'c');
      expect(p.toJson()['userId'], 'u1');
    });
  });

  group('Avatar', () {
    test('fromJson全フィールド', () {
      final a = Avatar.fromJson({'avatarId': 'a1', 'userId': 'u1', 'name': 'pig', 'totalPoints': 100, 'level': 5, 'evolutionStage': 2, 'stats': {'hp': 80, 'attack': 20, 'defense': 15, 'speed': 12}, 'skillIds': ['s1'], 'spriteSheetKey': 'sp'});
      expect(a.level, 5);
      expect(a.stats.hp, 80);
      expect(a.skillIds, ['s1']);
    });

    test('fromJsonデフォルト値', () {
      final a = Avatar.fromJson({'avatarId': 'a1', 'userId': 'u1'});
      expect(a.level, 1);
      expect(a.stats.hp, 0);
      expect(a.spriteSheetKey, 'sprites/stage1/default');
    });

    test('toJson', () {
      final a = Avatar(avatarId: 'a1', userId: 'u1', name: 'n', totalPoints: 0, level: 1, evolutionStage: 1, stats: AvatarStats(hp: 50, attack: 10, defense: 10, speed: 10), skillIds: [], spriteSheetKey: 'sp');
      expect(a.toJson()['avatarId'], 'a1');
    });
  });

  group('AvatarStats', () {
    test('fromJsonデフォルト', () {
      final s = AvatarStats.fromJson({});
      expect(s.hp, 0);
    });

    test('toJson', () {
      final s = AvatarStats(hp: 1, attack: 2, defense: 3, speed: 4);
      expect(s.toJson(), {'hp': 1, 'attack': 2, 'defense': 3, 'speed': 4});
    });
  });

  group('RecordSummary', () {
    test('fromJson', () {
      final s = RecordSummary.fromJson({'todayCount': 5, 'todayPoints': 100, 'date': '2026-05-24'});
      expect(s.todayCount, 5);
    });

    test('fromJsonフォールバック', () {
      final s = RecordSummary.fromJson({'count': 3, 'points': 60, 'date': '2026-05-24'});
      expect(s.todayCount, 3);
    });

    test('isToday', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(RecordSummary(todayCount: 0, todayPoints: 0, date: today).isToday, true);
      expect(RecordSummary(todayCount: 0, todayPoints: 0, date: '2020-01-01').isToday, false);
    });

    test('toJson', () {
      final s = RecordSummary(todayCount: 2, todayPoints: 30, date: '2026-05-24');
      expect(s.toJson()['todayCount'], 2);
    });
  });
}
