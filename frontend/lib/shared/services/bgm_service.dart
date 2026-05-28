import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BgmTrack { title, auth, home, record, battle, none }

abstract class AudioPlayerAdapter {
  Future<void> play(Source source);
  Future<void> stop();
  Future<void> setReleaseMode(ReleaseMode mode);
  Future<void> setVolume(double volume);
}

class RealAudioPlayerAdapter implements AudioPlayerAdapter {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> play(Source source) => _player.play(source);
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> setReleaseMode(ReleaseMode mode) => _player.setReleaseMode(mode);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
}

class BgmService {
  BgmService([AudioPlayerAdapter? player]) : _player = player ?? RealAudioPlayerAdapter();
  final AudioPlayerAdapter _player;
  BgmTrack _current = BgmTrack.none;

  BgmTrack get current => _current;

  static const _assets = {
    BgmTrack.title: 'bgm/title.mp3',
    BgmTrack.auth: 'bgm/auth.mp3',
    BgmTrack.home: 'bgm/home.mp3',
    BgmTrack.record: 'bgm/record.mp3',
    BgmTrack.battle: 'bgm/battle.mp3',
  };

  Future<void> play(BgmTrack track) async {
    if (track == _current) return;
    _current = track;
    if (track == BgmTrack.none) {
      await _player.stop();
      return;
    }
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
    await _player.play(AssetSource(_assets[track]!));
  }

  Future<void> stop() async {
    _current = BgmTrack.none;
    await _player.stop();
  }

  /// ルートパスからBGMトラックを判定
  static BgmTrack trackForRoute(String path) {
    if (path == '/start' || path == '/loading' || path == '/tutorial') return BgmTrack.title;
    if (path == '/login' || path == '/signup' || path == '/confirm' || path == '/nickname') return BgmTrack.auth;
    if (path.startsWith('/battle')) return BgmTrack.battle;
    if (path.startsWith('/record') || path == '/recording') return BgmTrack.record;
    if (path == '/evo-anim') return BgmTrack.none;
    return BgmTrack.home;
  }
}

final bgmServiceProvider = Provider<BgmService>((ref) => BgmService());
