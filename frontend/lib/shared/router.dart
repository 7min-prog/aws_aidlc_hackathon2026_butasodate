import 'package:flutter/material.dart';
import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/legal/legal_screen.dart';
import 'package:buta_app/features/start/start_screen.dart';
import 'package:buta_app/features/start/loading_screen.dart';
import 'package:buta_app/features/start/tutorial_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/record/category_select_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_complete_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';
import 'package:buta_app/features/battle/battle_ready_screen.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/avatar/avatar_detail_screen2.dart';
import 'package:buta_app/features/avatar/evo_book_screen.dart';
import 'package:buta_app/features/avatar/evo_anim_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/battle_history_screen.dart';
import 'package:buta_app/features/settings/profile_edit_screen.dart';
import 'package:buta_app/features/settings/health_data_screen.dart';
import 'package:buta_app/features/settings/notification_settings_screen.dart';
import 'package:buta_app/features/start/system_screens.dart';

/// レトロゲーム風フェードトランジション
CustomTransitionPage<void> pixelFadePage({required Widget child, required GoRouterState state}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final initialRouteProvider = Provider<String>((ref) => '/start');

final routerProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/start',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const StartScreen()),
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const LoadingScreen()),
      ),
      GoRoute(
        path: '/tutorial',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const TutorialScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/recording',
        pageBuilder: (context, state) => const NoTransitionPage(child: RecordTabScreen()),
      ),
      GoRoute(
        path: '/battle',
        pageBuilder: (context, state) => const NoTransitionPage(child: BattleTabScreen()),
      ),
      GoRoute(
        path: '/battle-matching',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const BattleMatchingScreen()),
      ),
      GoRoute(
        path: '/battle-ready',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const BattleReadyScreen()),
      ),
      GoRoute(
        path: '/battle-fight',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: BattleFightScreen(matchData: state.extra as Map<String, dynamic>?)),
      ),
      GoRoute(
        path: '/battle-result',
        pageBuilder: (context, state) { final extra = state.extra as Map<String, dynamic>? ?? {}; return pixelFadePage(state: state, child: BattleResultScreen(win: extra['win'] as bool? ?? true, myName: extra['myName'] as String? ?? '')); },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => const NoTransitionPage(child: AccountTabScreen()),
      ),
      GoRoute(
        path: '/avatar-detail',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: AvatarDetailScreen(avatar: state.extra as Map<String, dynamic>?)),
      ),
      GoRoute(
        path: '/evo-book',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const EvoBookScreen()),
      ),
      GoRoute(
        path: '/evo-anim',
        pageBuilder: (context, state) { final extra = state.extra as Map<String, dynamic>? ?? {}; return pixelFadePage(state: state, child: EvoAnimScreen(newName: extra['name'] as String? ?? 'ぽっちゃり', newLevel: extra['level'] as int? ?? 3)); },
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) => const NoTransitionPage(child: FriendListScreen()),
      ),
      GoRoute(
        path: '/friend-search',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const FriendSearchScreen()),
      ),
      GoRoute(
        path: '/battle-history',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const BattleHistoryScreen()),
      ),
      GoRoute(
        path: '/profile-edit',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const ProfileEditScreen()),
      ),
      GoRoute(
        path: '/health-data',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const HealthDataScreen()),
      ),
      GoRoute(
        path: '/notification-settings',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/record-category',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const CategorySelectScreen()),
      ),
      GoRoute(
        path: '/record-confirm',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: RecordConfirmScreen(category: state.extra as Map<String, dynamic>? ?? {})),
      ),
      GoRoute(
        path: '/record-complete',
        pageBuilder: (context, state) { final extra = state.extra as Map<String, dynamic>? ?? {}; return pixelFadePage(state: state, child: RecordCompleteScreen(points: extra['points'] as int? ?? 0)); },
      ),
      GoRoute(
        path: '/record-detail',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: RecordDetailScreen(record: state.extra as Map<String, dynamic>? ?? {})),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const SignupScreen()),
      ),
      GoRoute(
        path: '/confirm',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: ConfirmScreen(email: state.extra as String? ?? '')),
      ),
      GoRoute(
        path: '/nickname',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const NicknameScreen()),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) {
          final showTab = state.extra == false ? false : true;
          return pixelFadePage(state: state, child: LegalScreen(title: '利用規約', type: LegalType.terms, showTabBar: showTab));
        },
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) {
          final showTab = state.extra == false ? false : true;
          return pixelFadePage(state: state, child: LegalScreen(title: 'プライバシーポリシー', type: LegalType.privacy, showTabBar: showTab));
        },
      ),
      GoRoute(
        path: '/licenses',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const LicenseListScreen()),
      ),
      GoRoute(
        path: '/error',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const ErrorScreen()),
      ),
      GoRoute(
        path: '/maintenance',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const MaintenanceScreen()),
      ),
      GoRoute(
        path: '/force-update',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const ForceUpdateScreen()),
      ),
      GoRoute(
        path: '/health-consent',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const LegalScreen(title: 'ヘルスデータ どうい', type: LegalType.healthConsent)),
      ),
      GoRoute(
        path: '/commercial-law',
        pageBuilder: (context, state) => pixelFadePage(state: state, child: const LegalScreen(title: 'とくてい しょうとりひきほう', type: LegalType.commercialLaw)),
      ),
    ],
  );
});



