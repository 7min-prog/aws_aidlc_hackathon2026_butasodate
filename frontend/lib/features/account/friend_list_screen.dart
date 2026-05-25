import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';

final friendsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/social/friends');
    return (res.data['friends'] as List?) ?? [];
  } catch (_) {
    return [];
  }
});

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'フレンド'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 3)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Positioned(top: 20 * sy, right: 14 * sx, child: GestureDetector(
          onTap: () => context.push('/friend-search'),
          child: Container(
            width: 76 * sx, height: 32 * sy,
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            alignment: Alignment.center,
            child: Text('＋ ついか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
          ),
        )),
        Positioned(top: 70 * sy, left: 14 * sx, right: 14 * sx, bottom: 0, child: friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) return Center(child: Text('フレンドが いないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.gray)));
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: friends.length,
              itemBuilder: (_, i) {
                final f = friends[i];
                return Container(
                  height: 48 * sy, margin: EdgeInsets.only(bottom: 4 * sy),
                  padding: EdgeInsets.symmetric(horizontal: 12 * sx),
                  decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
                  child: Row(children: [
                    SvgPicture.asset('assets/pixel-art/icons/pig.svg', width: 28, height: 28),
                    SizedBox(width: 10 * sx),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(f['nickname'] ?? '', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                      Text('LV.${f['level'] ?? 1}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray)),
                    ]),
                    const Spacer(),
                    if (f['online'] == true) Container(width: 8, height: 8, decoration: BoxDecoration(color: ButaColors.green, shape: BoxShape.circle)),
                  ]),
                );
              },
            );
          },
          loading: () => Center(child: Text('よみこみちゅう...', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray))),
          error: (_, __) => Center(child: Text('エラー', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.red))),
        )),
      ]),
    );
  }
}
