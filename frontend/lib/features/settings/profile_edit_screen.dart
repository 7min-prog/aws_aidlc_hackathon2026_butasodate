import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/features/home/home_screen.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nickCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/users/me'),
        api.get('/avatar'),
      ]);
      final profile = results[0].data as Map<String, dynamic>? ?? {};
      final avatarData = results[1].data as Map<String, dynamic>? ?? {};
      final avatar = avatarData['avatar'] as Map<String, dynamic>? ?? avatarData;
      if (mounted) {
        setState(() {
          _nickCtrl.text = profile['nickname'] as String? ?? '';
          _avatarCtrl.text = avatar['name'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() { _nickCtrl.dispose(); _avatarCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.put('/users/profile', data: {'nickname': _nickCtrl.text.trim()});
      debugPrint('PUT /users/profile succeeded');
    } catch (e) {
      debugPrint('PUT /users/profile failed: $e');
      if (mounted) showPixelAlert(context, message: 'エラーが おきました');
      return;
    }
    try {
      if (_avatarCtrl.text.trim().isNotEmpty) {
        await api.put('/avatar/name', data: {'name': _avatarCtrl.text.trim()});
      }
    } catch (e) {
      debugPrint('PUT /avatar/name failed: $e');
      if (mounted) showPixelAlert(context, message: 'エラーが おきました');
      return;
    }
    if (mounted) await showPixelAlert(context, message: 'ほぞんしました！');
    if (mounted) {
      ref.invalidate(homeDataProvider);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'プロフィール', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover))),
        Positioned(top: 24 * sy, left: 0, right: 0, child: Text('ニックネーム', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper))),
        Positioned(top: 48 * sy, left: 55 * sx, child: PixelInput(controller: _nickCtrl, sx: sx, sy: sy, hintText: 'ニックネーム')),
        Positioned(top: 108 * sy, left: 0, right: 0, child: Text('アバターの なまえ', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper))),
        Positioned(top: 132 * sy, left: 55 * sx, child: PixelInput(controller: _avatarCtrl, sx: sx, sy: sy, hintText: 'アバターの なまえ')),
        Positioned(top: 200 * sy, left: 55 * sx, child: SizedBox(
          width: 280 * sx, height: 44 * sy,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ButaColors.yellow,
              foregroundColor: ButaColors.ink,
              shape: RoundedRectangleBorder(side: const BorderSide(color: ButaColors.ink, width: 2), borderRadius: BorderRadius.zero),
              textStyle: const TextStyle(fontFamily: kFontDotGothic16, fontSize: 16),
            ),
            onPressed: _save,
            child: const Text('ほぞんする'),
          ),
        )),
      ]),
    );
  }
}
