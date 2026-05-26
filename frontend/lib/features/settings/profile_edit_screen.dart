import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token') ?? '';
    final dio = Dio(BaseOptions(headers: {'Authorization': token}));
    try {
      final results = await Future.wait([
        dio.get('${AppConfig.authApiBase}/users/me'),
        dio.get('${AppConfig.avatarApiBase}/avatar'),
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      // Cognito AuthorizerはIDトークンを要求する場合がある
      final idToken = prefs.getString('id_token');
      final authToken = idToken ?? token;
      if (authToken == null) {
        if (mounted) showPixelAlert(context, message: 'トークンなし');
        return;
      }
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json', 'Authorization': authToken},
      ));
      await dio.put('${AppConfig.authApiBase}/users/profile', data: {'nickname': _nickCtrl.text.trim()});
      // アバター名も更新
      if (_avatarCtrl.text.trim().isNotEmpty) {
        await dio.put('${AppConfig.avatarApiBase}/avatar/name', data: {'name': _avatarCtrl.text.trim()});
      }
      if (mounted) await showPixelAlert(context, message: 'ほぞんしました！');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final msg = e is DioException ? '${e.response?.statusCode ?? e.type}' : e.runtimeType.toString();
        showPixelAlert(context, message: 'エラー: $msg');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
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
