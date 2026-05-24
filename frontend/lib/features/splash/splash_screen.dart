import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // デバッグ: 環境変数でauto loginが設定されている場合
    const autoLogin = String.fromEnvironment('AUTO_LOGIN', defaultValue: '');
    if (autoLogin.isNotEmpty) {
      final parts = autoLogin.split(':');
      if (parts.length == 2) {
        await ref.read(authStateProvider.notifier).login(parts[0], parts[1]);
        if (!mounted) return;
        context.go('/home');
        return;
      }
    }

    final tokens = await ref.read(authStateProvider.future);
    if (!mounted) return;
    if (tokens != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Center(
        child: Text('ぶたそだて', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 24, color: ButaColors.paper)),
      ),
    );
  }
}
