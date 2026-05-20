import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/confirm';

      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/confirm',
        builder: (context, state) => ConfirmScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/nickname',
        builder: (context, state) => const NicknameScreen(),
      ),
    ],
  );
});

// 仮のホーム画面（後のユニットで差し替え）
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ぶたそだて')),
      body: const Center(child: Text('ホーム画面（後で実装）')),
    );
  }
}
