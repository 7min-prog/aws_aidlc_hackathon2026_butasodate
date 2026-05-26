import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/pixel_loader.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';

String _shortId(dynamic id) {
  final s = id?.toString() ?? '';
  return s.length > 8 ? '${s.substring(0, 8)}...' : (s.isEmpty ? 'あいて' : s);
}

Future<Dio> _getAuthDio() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('id_token') ?? prefs.getString('access_token') ?? '';
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Authorization': token},
  ));
}

final battleHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final dio = await _getAuthDio();
    final res = await dio.get('${AppConfig.socialApiBase}/battles/history');
    return (res.data['history'] as List?) ?? [];
  } catch (e) {
    debugPrint('battleHistory error: $e');
    return [];
  }
});

final rankingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final dio = await _getAuthDio();
    final res = await dio.get('${AppConfig.socialApiBase}/rankings');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token') ?? '';
    String myId = '';
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        myId = (jsonDecode(payload) as Map<String, dynamic>)['sub'] ?? '';
      }
    } catch (_) {}
    return {'rankings': (res.data['rankings'] as List?) ?? [], 'myId': myId};
  } catch (_) {
    return {'rankings': <dynamic>[], 'myId': ''};
  }
});

final friendsForBattleProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final dio = await _getAuthDio();
    final res = await dio.get('${AppConfig.socialApiBase}/social/friends');
    return (res.data['friends'] as List?) ?? [];
  } catch (_) {
    return [];
  }
});

class BattleTabScreen extends ConsumerWidget {
  const BattleTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'バトル'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 2)),
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover))),
        const Positioned.fill(child: IgnorePointer(child: CloudAnimation())),
        Positioned.fill(child: IgnorePointer(child: GrassAnimation(sx: sx, sy: sy))),
        Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * sx, vertical: 10),
        child: Column(children: [
          // ランダムマッチ
          GestureDetector(
            onTap: () => context.go('/battle-matching'),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SvgPicture.asset('assets/pixel-art/icons/swords.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(ButaColors.paper, BlendMode.srcIn)),
                const Text('ランダムマッチ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // フレンド対戦
          GestureDetector(
            onTap: () async {
              try {
                final list = await ref.read(friendsForBattleProvider.future);
                if (!context.mounted || list.isEmpty) return;
                final selected = await showDialog<String>(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 3)),
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('フレンドを えらぶ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
                      const SizedBox(height: 12),
                      ...list.map<Widget>((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ButaColors.bg, foregroundColor: ButaColors.ink,
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => Navigator.pop(ctx, f['nickname'] ?? f['userId']),
                          child: Text(f['nickname'] ?? f['userId'], style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 14)),
                        ),
                      )),
                    ]),
                  ),
                ),
              );
              if (selected != null && context.mounted) context.go('/battle-matching');
              } catch (_) {}
            },
            child: Container(
              width: double.infinity, height: 44,
              decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/mail.svg', width: 16, height: 16), const SizedBox(width: 6), const Text('フレンド たいせん', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))]),
            ),
          ),
          const SizedBox(height: 12),
          // 履歴タイトル
          const Align(alignment: Alignment.centerLeft, child: Text('バトル りれき', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink))),
          const SizedBox(height: 6),
          // 履歴リスト
          SizedBox(height: 160, child: Container(
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            padding: const EdgeInsets.all(8),
            child: ref.watch(battleHistoryProvider).when(
              data: (history) {
                if (history.isEmpty) return const Center(child: Text('まだ りれきが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)));
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final h = history[i];
                    final win = h['result'] == 'WIN';
                    return Container(
                      height: 36, margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      color: win ? ButaColors.green.withValues(alpha: 0.15) : ButaColors.red.withValues(alpha: 0.15),
                      child: Row(children: [
                        SizedBox(width: 40, child: Text(win ? 'WIN' : 'LOSE', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: win ? ButaColors.green : ButaColors.red))),
                        Text('vs ${h['opponentName'] ?? h['opponentNickname'] ?? _shortId(h['opponentId'])}', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                        const Spacer(),
                        Text('${(h['pointChange'] ?? 0) > 0 ? '+' : ''}${h['pointChange'] ?? 0}pt', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: PixelLoader()),
              error: (_, __) => const Center(child: Text('まだ りれきが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
            ),
          )),
          const SizedBox(height: 12),
          // ランキング
          const Align(alignment: Alignment.centerLeft, child: Text('ランキング', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink))),
          const SizedBox(height: 6),
          Expanded(child: Container(
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            padding: const EdgeInsets.all(8),
            child: ref.watch(rankingsProvider).when(
              data: (data) {
                final rankings = data['rankings'] as List;
                final myId = data['myId'] as String;
                if (rankings.isEmpty) return const Center(child: Text('データなし', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)));
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: rankings.length,
                  itemBuilder: (_, i) {
                    final r = rankings[i] as Map<String, dynamic>;
                    final isMe = r['userId'] == myId;
                    return Container(
                      height: 32, margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      color: isMe ? ButaColors.blue.withValues(alpha: 0.2) : (i < 3 ? ButaColors.yellow.withValues(alpha: 0.15) : null),
                      child: Row(children: [
                        SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 10, color: i < 3 ? ButaColors.yellow : ButaColors.gray))),
                        Expanded(child: Text(r['nickname'] ?? _shortId(r['userId']), style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink))),
                        if (isMe) const Text('YOU ', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.blue)),
                        Text('${r['points'] ?? 0}pt', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: PixelLoader()),
              error: (_, __) => const Center(child: Text('データなし', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
            ),
          )),
        ]),
      ),
      ]),
    );
  }
}
