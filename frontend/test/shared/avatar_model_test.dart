import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/models/avatar.dart';

void main() {
  group('AvatarStats', () {
    test('fromJson parses correctly', () {
      final stats = AvatarStats.fromJson({'hp': 100, 'attack': 20, 'defense': 15, 'speed': 10});
      expect(stats.hp, 100);
      expect(stats.attack, 20);
      expect(stats.defense, 15);
      expect(stats.speed, 10);
    });

    test('fromJson handles missing fields', () {
      final stats = AvatarStats.fromJson({});
      expect(stats.hp, 0);
      expect(stats.attack, 0);
    });

    test('toJson round-trip', () {
      final stats = AvatarStats(hp: 50, attack: 10, defense: 5, speed: 3);
      final json = stats.toJson();
      final restored = AvatarStats.fromJson(json);
      expect(restored.hp, 50);
      expect(restored.speed, 3);
    });
  });

  group('Avatar', () {
    test('fromJson parses full data', () {
      final avatar = Avatar.fromJson({
        'avatarId': 'a1',
        'userId': 'u1',
        'name': 'ぶたさん',
        'totalPoints': 500,
        'level': 5,
        'evolutionStage': 2,
        'evolutionPathId': 'path1',
        'stats': {'hp': 100, 'attack': 20, 'defense': 15, 'speed': 10},
        'skillIds': ['fire', 'ice'],
        'spriteSheetKey': 'sprites/stage2/pocchari',
      });
      expect(avatar.avatarId, 'a1');
      expect(avatar.name, 'ぶたさん');
      expect(avatar.level, 5);
      expect(avatar.evolutionPathId, 'path1');
      expect(avatar.skillIds, ['fire', 'ice']);
      expect(avatar.spriteSheetKey, 'sprites/stage2/pocchari');
    });

    test('fromJson handles defaults', () {
      final avatar = Avatar.fromJson({'avatarId': 'a2', 'userId': 'u2'});
      expect(avatar.name, '');
      expect(avatar.totalPoints, 0);
      expect(avatar.level, 1);
      expect(avatar.evolutionStage, 1);
      expect(avatar.evolutionPathId, isNull);
      expect(avatar.skillIds, isEmpty);
      expect(avatar.spriteSheetKey, 'sprites/stage1/default');
    });

    test('toJson round-trip', () {
      final avatar = Avatar(avatarId: 'a1', userId: 'u1', name: 'test', totalPoints: 10, level: 1, evolutionStage: 1, stats: AvatarStats(hp: 1, attack: 1, defense: 1, speed: 1), skillIds: [], spriteSheetKey: 'k');
      final json = avatar.toJson();
      final restored = Avatar.fromJson(json);
      expect(restored.avatarId, 'a1');
      expect(restored.name, 'test');
    });
  });
}
