import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/splash/splash_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/recording/recording_screen.dart';
import 'package:buta_app/features/battle/battle_screen.dart';
import 'package:buta_app/features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/recording',
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: '/battle',
        builder: (context, state) => const BattleScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
        builder: (context, state) => ConfirmScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/nickname',
        builder: (context, state) => const NicknameScreen(),
      ),
    ],
  );
});
