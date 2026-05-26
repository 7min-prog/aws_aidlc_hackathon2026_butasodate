import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/repositories/auth_repository.dart';
import 'package:buta_app/shared/repositories/avatar_repository.dart';
import 'package:buta_app/shared/repositories/recording_repository.dart';
import 'package:buta_app/shared/repositories/social_repository.dart';
import 'package:buta_app/shared/services/api_client.dart';

void main() {
  group('AuthRepository', () {
    late Dio dio;
    late DioAdapter adapter;
    late AuthRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      adapter = DioAdapter(dio: dio);
      repo = AuthRepository(dio);
    });

    test('login returns tokens', () async {
      adapter.onPost('/auth/login', (s) => s.reply(200, {'accessToken': 'a', 'refreshToken': 'r', 'idToken': 'i'}), data: Matchers.any);
      final result = await repo.login('t@t.com', 'p');
      expect(result['accessToken'], 'a');
      expect(result['refreshToken'], 'r');
    });

    test('signup succeeds', () async {
      adapter.onPost('/auth/signup', (s) => s.reply(200, {}), data: Matchers.any);
      await repo.signup('t@t.com', 'p');
    });

    test('confirmSignup succeeds', () async {
      adapter.onPost('/auth/confirm', (s) => s.reply(200, {}), data: Matchers.any);
      await repo.confirmSignup('t@t.com', '123456');
    });

    test('refreshToken returns new tokens', () async {
      adapter.onPost('/auth/refresh', (s) => s.reply(200, {'accessToken': 'new', 'idToken': 'id'}), data: Matchers.any);
      final result = await repo.refreshToken('old_refresh');
      expect(result['accessToken'], 'new');
    });
  });

  group('AvatarRepository', () {
    late Dio dio;
    late DioAdapter adapter;
    late AvatarRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      adapter = DioAdapter(dio: dio);
      repo = AvatarRepository(_FakeApiClient(dio));
    });

    test('getAvatar returns avatar', () async {
      adapter.onGet('/avatar', (s) => s.reply(200, {'avatar': {'avatarId': 'a1', 'userId': 'u1', 'name': 'ぶた', 'totalPoints': 100, 'level': 2, 'evolutionStage': 1, 'stats': {'hp': 50, 'attack': 10, 'defense': 5, 'speed': 3}, 'skillIds': [], 'spriteSheetKey': 'sprites/stage1/default'}}));
      final avatar = await repo.getAvatar();
      expect(avatar?.name, 'ぶた');
      expect(avatar?.level, 2);
    });

    test('getAvatar returns null on error', () async {
      adapter.onGet('/avatar', (s) => s.reply(404, {}));
      final avatar = await repo.getAvatar();
      expect(avatar, isNull);
    });

    test('createAvatar returns avatar', () async {
      adapter.onPost('/avatar', (s) => s.reply(201, {'avatar': {'avatarId': 'a1', 'userId': 'u1', 'name': 'テスト', 'totalPoints': 0, 'level': 1, 'evolutionStage': 1, 'stats': {'hp': 100, 'attack': 10, 'defense': 10, 'speed': 10}, 'skillIds': [], 'spriteSheetKey': 'sprites/stage1/default'}}), data: Matchers.any);
      final avatar = await repo.createAvatar('テスト');
      expect(avatar?.name, 'テスト');
    });
  });

  group('RecordingRepository', () {
    late Dio dio;
    late DioAdapter adapter;
    late RecordingRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      adapter = DioAdapter(dio: dio);
      repo = RecordingRepository(_FakeApiClient(dio));
    });

    test('getActivities returns records and summary', () async {
      adapter.onGet('/activities', (s) => s.reply(200, {
        'records': [{'recordId': 'r1', 'categoryId': 'food-ramen', 'points': 50, 'recordedAt': '2026-05-25T12:00:00Z', 'source': 'MANUAL'}],
        'summary': {'todayCount': 1, 'todayPoints': 50, 'weekByCategory': []},
      }), queryParameters: {'limit': 20});
      final result = await repo.getActivities();
      expect((result['records'] as List).length, 1);
      expect(result['summary']['todayCount'], 1);
    });

    test('recordActivity returns result with avatar update', () async {
      adapter.onPost('/activities', (s) => s.reply(201, {
        'avatar': {'totalPoints': 50, 'level': 1, 'evolutionStage': 1, 'categoryPoints': {'FOOD': 50}},
        'leveledUp': false, 'evolved': false, 'newSkills': [], 'skippedIds': [],
      }), data: Matchers.any);
      final result = await repo.recordActivity(categoryId: 'food-ramen');
      expect(result['leveledUp'], isFalse);
      expect(result['avatar']['totalPoints'], 50);
    });

    test('getSummary returns RecordSummary', () async {
      adapter.onGet('/activities', (s) => s.reply(200, {
        'records': [], 'summary': {'todayCount': 3, 'todayPoints': 45, 'date': '2026-05-25'},
      }), queryParameters: {'limit': 1});
      final summary = await repo.getSummary();
      expect(summary?.todayCount, 3);
    });

    test('getSummary returns null on error', () async {
      adapter.onGet('/activities', (s) => s.reply(500, {}), queryParameters: {'limit': 1});
      final summary = await repo.getSummary();
      expect(summary, isNull);
    });

    test('getCategories returns list', () async {
      adapter.onGet('/categories', (s) => s.reply(200, {'categories': [{'id': 'food-ramen', 'name': '深夜ラーメン'}]}));
      final cats = await repo.getCategories();
      expect(cats.length, 1);
      expect(cats[0]['id'], 'food-ramen');
    });
  });

  group('SocialRepository', () {
    late Dio dio;
    late DioAdapter adapter;
    late SocialRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      adapter = DioAdapter(dio: dio);
      repo = SocialRepository(_FakeApiClient(dio));
    });

    test('getFriends returns list', () async {
      adapter.onGet('/social/friends', (s) => s.reply(200, {'friends': [{'userId': 'f1', 'nickname': 'フレンド'}]}));
      final friends = await repo.getFriends();
      expect(friends.length, 1);
      expect(friends[0]['nickname'], 'フレンド');
    });

    test('getPendingRequests returns list', () async {
      adapter.onGet('/social/friends/requests', (s) => s.reply(200, {'requests': [{'id': 'req1'}, {'id': 'req2'}]}));
      final requests = await repo.getPendingRequests();
      expect(requests.length, 2);
    });

    test('getRankings returns list', () async {
      adapter.onGet('/rankings', (s) => s.reply(200, {'rankings': [{'userId': 'u1', 'points': 1000, 'wins': 5, 'losses': 2}]}));
      final rankings = await repo.getRankings();
      expect(rankings[0]['points'], 1000);
    });

    test('sendFriendRequest succeeds', () async {
      adapter.onPost('/social/friends/request', (s) => s.reply(200, {}), data: Matchers.any);
      await repo.sendFriendRequest('user-2');
    });

    test('respondToRequest succeeds', () async {
      adapter.onPost('/social/friends/respond', (s) => s.reply(200, {}), data: Matchers.any);
      await repo.respondToRequest('req-1', true);
    });

    test('getBattleHistory returns list', () async {
      adapter.onGet('/battles/history', (s) => s.reply(200, {'history': [{'battleId': 'b1', 'result': 'WIN'}]}));
      final history = await repo.getBattleHistory();
      expect(history.length, 1);
    });
  });
}

/// テスト用ApiClient（Dioを直接使用）
class _FakeApiClient implements ApiClient {
  final Dio _dio;
  _FakeApiClient(this._dio);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
  @override
  Future<Response> post(String path, {Object? data}) =>
      _dio.post(path, data: data);
  @override
  Future<Response> put(String path, {Object? data}) =>
      _dio.put(path, data: data);
  @override
  Future<Response> delete(String path) =>
      _dio.delete(path);
}
