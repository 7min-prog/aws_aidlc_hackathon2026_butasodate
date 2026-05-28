import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/utils/error_helper.dart';

/// 検索結果プロバイダー（クエリをfamilyパラメータとして受け取る）
final friendSearchResultsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final api = ref.read(apiClientProvider);
  final res = await api.post('/social/friends/search', data: {'query': query});
  return List<Map<String, dynamic>>.from(res.data['users'] ?? []);
});

class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({super.key});
  @override
  ConsumerState<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  final _queryCtrl = TextEditingController();
  final Set<String> _requested = {};
  String _searchQuery = '';

  void _search() {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _searchQuery = query);
  }

  Future<void> _sendRequest(String targetUserId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/social/friends/request', data: {'targetUserId': targetUserId});
      setState(() => _requested.add(targetUserId));
      if (mounted) showPixelAlert(context, title: 'おくりました', message: 'フレンドしんせいを\nおくりました！');
    } catch (e) {
      if (mounted) showPixelAlert(context, message: 'エラーが おきました\n\n${formatApiError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final results = ref.watch(friendSearchResultsProvider(_searchQuery));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'フレンド けんさく', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 3)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        // 検索入力欄
        Positioned(top: 20 * sy, left: 14 * sx, child: PixelInput(controller: _queryCtrl, sx: sx, sy: sy, hintText: 'ニックネーム / ID')),
        // けんさくボタン
        Positioned(top: 20 * sy, right: 14 * sx, child: GestureDetector(
          onTap: _search,
          child: Container(
            width: 72 * sx, height: 36 * sy,
            decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: const Text('けんさく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink)),
          ),
        )),
        // けっか
        Positioned(top: 76 * sy, left: 14 * sx, child: const Text('けっか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray))),
        // 検索結果リスト
        Positioned(top: 96 * sy, left: 14 * sx, right: 14 * sx, bottom: 0, child: results.when(
          loading: () => Center(child: _PixelLoader(sx: sx, sy: sy)),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) => ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: 8 * sy),
              itemBuilder: (_, i) {
                final user = list[i];
                final userId = user['userId'] as String? ?? '';
                final nickname = user['nickname'] as String? ?? '';
                final level = user['level'] as int? ?? 1;
                final sent = _requested.contains(userId);
                return Container(
                  height: 52 * sy,
                  padding: EdgeInsets.symmetric(horizontal: 12 * sx),
                  decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                  child: Row(children: [
                    Container(width: 36 * sx, height: 36 * sy, color: ButaColors.blue, alignment: Alignment.center, child: SvgPicture.asset('assets/pixel-art/icons/pig.svg', width: 16, height: 16)),
                    SizedBox(width: 10 * sx),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(nickname, style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                      Text('LV.$level', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray)),
                    ])),
                    GestureDetector(
                      onTap: sent ? null : () => _sendRequest(userId),
                      child: Container(
                        width: 80 * sx, height: 28 * sy,
                        decoration: BoxDecoration(color: sent ? ButaColors.gray : ButaColors.green, border: Border.all(color: ButaColors.ink, width: 1)),
                        alignment: Alignment.center,
                        child: Text(sent ? 'しんせいずみ' : 'ついか', style: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper)),
                      ),
                    ),
                  ]),
                );
              },
            ),
        )),
      ]),
    );
  }
}

class _PixelLoader extends StatefulWidget {
  const _PixelLoader({required this.sx, required this.sy});
  final double sx, sy;
  @override
  State<_PixelLoader> createState() => _PixelLoaderState();
}

class _PixelLoaderState extends State<_PixelLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final frame = (_ctrl.value * 4).floor() % 4;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) => Container(
            width: 10 * widget.sx,
            height: 10 * widget.sy,
            margin: EdgeInsets.symmetric(horizontal: 3 * widget.sx),
            color: i == frame ? ButaColors.yellow : ButaColors.paper,
          )),
        );
      },
    );
  }
}
