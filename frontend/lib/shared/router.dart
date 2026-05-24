import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/legal/legal_screen.dart';
import 'package:buta_app/features/splash/splash_screen.dart';
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
import 'package:buta_app/features/settings/account_manage_screen.dart';
import 'package:buta_app/features/start/system_screens.dart';

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
        builder: (context, state) => const BattleMatchingScreen(),
      ),
      GoRoute(
        path: '/battle-ready',
        builder: (context, state) => const BattleReadyScreen(),
      ),
      GoRoute(
        path: '/battle-fight',
        builder: (context, state) => const BattleFightScreen(),
      ),
      GoRoute(
        path: '/battle-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BattleResultScreen(win: extra['win'] as bool? ?? true);
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => const NoTransitionPage(child: AccountTabScreen()),
      ),
      GoRoute(
        path: '/avatar-detail',
        builder: (context, state) => AvatarDetailScreen(avatar: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/evo-book',
        builder: (context, state) => const EvoBookScreen(),
      ),
      GoRoute(
        path: '/evo-anim',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EvoAnimScreen(newName: extra['name'] as String? ?? 'ぽっちゃり', newLevel: extra['level'] as int? ?? 3);
        },
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) => const NoTransitionPage(child: FriendListScreen()),
      ),
      GoRoute(
        path: '/friend-search',
        builder: (context, state) => const FriendSearchScreen(),
      ),
      GoRoute(
        path: '/battle-history',
        builder: (context, state) => const BattleHistoryScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/health-data',
        builder: (context, state) => const HealthDataScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/account-manage',
        builder: (context, state) => const AccountManageScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/record-category',
        builder: (context, state) => const CategorySelectScreen(),
      ),
      GoRoute(
        path: '/record-confirm',
        builder: (context, state) => RecordConfirmScreen(category: state.extra as Map<String, dynamic>? ?? {}),
      ),
      GoRoute(
        path: '/record-complete',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RecordCompleteScreen(points: extra['points'] as int? ?? 0);
        },
      ),
      GoRoute(
        path: '/record-detail',
        builder: (context, state) => RecordDetailScreen(record: state.extra as Map<String, dynamic>? ?? {}),
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
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(title: '利用規約', type: LegalType.terms),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(title: 'プライバシーポリシー', type: LegalType.privacy),
      ),
      GoRoute(
        path: '/licenses',
        builder: (context, state) => const LicenseListScreen(),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => const ErrorScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/force-update',
        builder: (context, state) => const ForceUpdateScreen(),
      ),
      GoRoute(
        path: '/health-consent',
        builder: (context, state) => const LegalScreen(title: 'ヘルスデータ どうい', type: LegalType.healthConsent),
      ),
      GoRoute(
        path: '/commercial-law',
        builder: (context, state) => const LegalScreen(title: 'とくてい しょうとりひきほう', type: LegalType.commercialLaw),
      ),
    ],
  );
});



