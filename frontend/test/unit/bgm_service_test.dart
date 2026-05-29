import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/services/bgm_service.dart';

class MockAudioPlayer implements AudioPlayerAdapter {
  int playCount = 0;
  int stopCount = 0;
  ReleaseMode? lastMode;
  double? lastVolume;

  @override
  Future<void> play(Source source) async => playCount++;
  @override
  Future<void> stop() async => stopCount++;
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async => lastMode = mode;
  @override
  Future<void> setVolume(double volume) async => lastVolume = volume;
}

void main() {
  group('BgmService.trackForRoute', () {
    test('X系 routes return title', () {
      expect(BgmService.trackForRoute('/start'), BgmTrack.title);
      expect(BgmService.trackForRoute('/loading'), BgmTrack.title);
      expect(BgmService.trackForRoute('/tutorial'), BgmTrack.title);
    });

    test('A系 routes return auth', () {
      expect(BgmService.trackForRoute('/login'), BgmTrack.auth);
      expect(BgmService.trackForRoute('/signup'), BgmTrack.auth);
      expect(BgmService.trackForRoute('/confirm'), BgmTrack.auth);
      expect(BgmService.trackForRoute('/nickname'), BgmTrack.auth);
    });

    test('B系 routes return battle', () {
      expect(BgmService.trackForRoute('/battle'), BgmTrack.battle);
      expect(BgmService.trackForRoute('/battle-fight'), BgmTrack.battle);
    });

    test('R系 routes return record', () {
      expect(BgmService.trackForRoute('/recording'), BgmTrack.record);
      expect(BgmService.trackForRoute('/record-category'), BgmTrack.record);
    });

    test('V-02 returns none', () {
      expect(BgmService.trackForRoute('/evo-anim'), BgmTrack.none);
    });

    test('M系 routes return home', () {
      expect(BgmService.trackForRoute('/home'), BgmTrack.home);
      expect(BgmService.trackForRoute('/'), BgmTrack.home);
      expect(BgmService.trackForRoute('/settings'), BgmTrack.home);
    });
  });

  group('BgmService.play', () {
    test('plays track and sets state', () async {
      final mock = MockAudioPlayer();
      final bgm = BgmService(mock);
      expect(bgm.current, BgmTrack.none);

      await bgm.play(BgmTrack.title);
      expect(bgm.current, BgmTrack.title);
      expect(mock.playCount, 1);
      expect(mock.stopCount, 1); // stop before play
      expect(mock.lastMode, ReleaseMode.loop);
      expect(mock.lastVolume, 0.5);
    });

    test('same track does nothing', () async {
      final mock = MockAudioPlayer();
      final bgm = BgmService(mock);
      await bgm.play(BgmTrack.battle);
      await bgm.play(BgmTrack.battle);
      expect(mock.playCount, 1);
    });

    test('none stops player', () async {
      final mock = MockAudioPlayer();
      final bgm = BgmService(mock);
      await bgm.play(BgmTrack.home);
      await bgm.play(BgmTrack.none);
      expect(bgm.current, BgmTrack.none);
      expect(mock.stopCount, 2); // stop for home + stop for none
    });

    test('switching tracks stops and plays new', () async {
      final mock = MockAudioPlayer();
      final bgm = BgmService(mock);
      await bgm.play(BgmTrack.title);
      await bgm.play(BgmTrack.battle);
      expect(mock.playCount, 2);
      expect(mock.stopCount, 2);
      expect(bgm.current, BgmTrack.battle);
    });
  });

  group('BgmService.stop', () {
    test('stops and resets to none', () async {
      final mock = MockAudioPlayer();
      final bgm = BgmService(mock);
      await bgm.play(BgmTrack.record);
      await bgm.stop();
      expect(bgm.current, BgmTrack.none);
      expect(mock.stopCount, 2);
    });
  });
}
