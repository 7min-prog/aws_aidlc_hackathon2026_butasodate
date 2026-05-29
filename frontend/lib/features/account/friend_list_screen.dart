import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_loader.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/utils/error_helper.dart';

final friendListProvider = FutureProvider.autoDispose<Map<String, List<dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  List<dynamic> friends = [];
  List<dynamic> requests = [];
  try {
    final res = await api.get('/social/friends');
    friends = (res.data['friends'] as List?) ?? [];
  } catch (_) {}
  try {
    final res = await api.get('/social/friends/requests');
    requests = (res.data['requests'] as List?) ?? [];
  } catch (_) {}
  return {'friends': friends, 'requests': requests};
});

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});
  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  List<dynamic> _friends = [];
  List<dynamic> _requests = [];
  bool _initialized = false;

  Future<void> _deleteFriend(String friendId) async {
    final confirmed = await showPixelConfirm(context, title: 'フレンドさくじょ', message: 'このフレンドを\nさくじょしますか？');
    if (confirmed != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/social/friends/$friendId');
      setState(() => _friends.removeWhere((f) => (f['friendId'] ?? f['userId']) == friendId));
    } catch (e) {
      if (mounted) showPixelAlert(context, message: 'エラーが おきました\n\n${formatApiError(e)}');
    }
  }

  Future<void> _respond(String requestId, bool accept) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/social/friends/respond', data: {'requestId': requestId, 'accept': accept});
      setState(() => _requests.removeWhere((r) => r['requestId'] == requestId));
      if (accept) ref.invalidate(friendListProvider);
      if (mounted) showPixelAlert(context, message: accept ? 'しょうにん しました！' : 'きょひ しました');
    } catch (e) {
      if (mounted) showPixelAlert(context, message: 'エラーが おきました\n\n${formatApiError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final data = ref.watch(friendListProvider);

    // Sync provider data to local state
    data.whenData((d) {
      if (!_initialized || _friends.isEmpty && d['friends']!.isNotEmpty) {
        _friends = List.from(d['friends']!);
        _requests = List.from(d['requests']!);
        _initialized = true;
      }
    });

    final loading = data.isLoading && !_initialized;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'フレンド'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 3)),
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover))),
        // ＋ついかボタン
        Positioned(top: 10 * sy, right: 14 * sx, child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ButaColors.paper, foregroundColor: ButaColors.ink,
            shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink), borderRadius: BorderRadius.zero),
            padding: EdgeInsets.symmetric(horizontal: 12 * sx),
            minimumSize: Size(0, 32 * sy),
          ),
          onPressed: () => context.push('/friend-search'),
          child: const Text('＋ ついか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10)),
        )),
        // コンテンツ
        Positioned(top: 50 * sy, left: 14 * sx, right: 14 * sx, bottom: 0, child: loading
          ? const Center(child: PixelLoader())
          : ListView(padding: EdgeInsets.zero, children: [
              // 申請セクション
              if (_requests.isNotEmpty) ...[
                Text('しんせい (${_requests.length})', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.yellow)),
                SizedBox(height: 4 * sy),
                ..._requests.map((r) => Container(
                  height: 52 * sy, margin: EdgeInsets.only(bottom: 4 * sy),
                  padding: EdgeInsets.symmetric(horizontal: 10 * sx),
                  decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.yellow, width: 2)),
                  child: Row(children: [
                    SvgPicture.asset('assets/pixel-art/icons/pig.svg', width: 24, height: 24),
                    SizedBox(width: 8 * sx),
                    Expanded(child: Text(r['fromNickname'] ?? r['fromUserId'] ?? r['from'] ?? '???', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ButaColors.green, minimumSize: Size(50 * sx, 28 * sy), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink), borderRadius: BorderRadius.zero)),
                      onPressed: () => _respond(r['requestId'], true),
                      child: const Text('OK', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper)),
                    ),
                    SizedBox(width: 4 * sx),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ButaColors.gray, minimumSize: Size(50 * sx, 28 * sy), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink), borderRadius: BorderRadius.zero)),
                      onPressed: () => _respond(r['requestId'], false),
                      child: const Text('NG', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper)),
                    ),
                  ]),
                )),
                SizedBox(height: 12 * sy),
              ],
              // フレンドリスト
              Text('フレンド (${_friends.length})', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray)),
              SizedBox(height: 4 * sy),
              if (_friends.isEmpty)
                Center(child: Padding(padding: EdgeInsets.only(top: 20 * sy), child: const Text('フレンドが いないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.gray))))
              else
                ..._friends.map((f) => Container(
                  height: 48 * sy, margin: EdgeInsets.only(bottom: 4 * sy),
                  padding: EdgeInsets.symmetric(horizontal: 12 * sx),
                  decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                  child: Row(children: [
                    SvgPicture.asset('assets/pixel-art/icons/pig.svg', width: 28, height: 28),
                    SizedBox(width: 10 * sx),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(f['nickname'] ?? '', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                      Text('LV.${f['level'] ?? 1}', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray)),
                    ]),
                    const Spacer(),
                    if (f['online'] == true) Container(width: 8, height: 8, decoration: const BoxDecoration(color: ButaColors.green, shape: BoxShape.circle)),
                    SizedBox(width: 8 * sx),
                    GestureDetector(
                      onTap: () => _deleteFriend(f['friendId'] ?? f['userId'] ?? ''),
                      child: const Icon(Icons.close, size: 18, color: ButaColors.red),
                    ),
                  ]),
                )),
            ]),
        ),
      ]),
    );
  }
}
