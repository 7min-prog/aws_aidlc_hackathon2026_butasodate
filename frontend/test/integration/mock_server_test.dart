// mockサーバーとの疎通テスト
// 実行前に mock-server を起動: cd mock-server && npm run dev
// 実行: dart test test/integration/mock_server_test.dart

import 'package:dio/dio.dart';
import 'package:test/test.dart';

const baseUrl = 'http://localhost:3000';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {'Content-Type': 'application/json'}));
  });

  group('Health', () {
    test('GET /health returns ok', () async {
      final res = await dio.get('/health');
      expect(res.statusCode, 200);
      expect(res.data['status'], 'ok');
    });
  });

  group('Auth Flow', () {
    test('signup → confirm → login → me', () async {
      final email = 'dart${DateTime.now().millisecondsSinceEpoch}@test.com';
      // Signup
      final signup = await dio.post('/auth/signup', data: {'email': email, 'password': 'Test1234!'});
      expect(signup.statusCode, 200);

      // Confirm
      final confirm = await dio.post('/auth/confirm', data: {'email': email, 'code': '123456'});
      expect(confirm.statusCode, 200);

      // Login
      final login = await dio.post('/auth/login', data: {'email': email, 'password': 'Test1234!'});
      expect(login.statusCode, 200);
      final token = login.data['accessToken'] as String;
      expect(token, contains('mock-token-'));

      // Get profile
      final me = await dio.get('/users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      expect(me.statusCode, 200);
      expect(me.data['userId'], isNotEmpty);
    });
  });

  group('Recording Flow', () {
    test('categories → record → get activities', () async {
      final token = 'mock-token-dart-user';
      final auth = Options(headers: {'Authorization': 'Bearer $token'});

      // Get categories
      final cats = await dio.get('/categories');
      expect(cats.statusCode, 200);
      expect((cats.data['categories'] as List).length, 8);

      // Record activity
      final record = await dio.post('/activities', data: {
        'records': [{'categoryId': 'food-ramen'}]
      }, options: auth);
      expect(record.statusCode, 201);
      expect(record.data['avatar']['totalPoints'], greaterThan(0));

      // Get activities
      final activities = await dio.get('/activities', options: auth);
      expect(activities.statusCode, 200);
      expect((activities.data['records'] as List).length, greaterThan(0));
    });
  });

  group('Avatar Flow', () {
    test('create → get avatar', () async {
      final token = 'mock-token-dart-avatar';
      final auth = Options(headers: {'Authorization': 'Bearer $token'});

      // Create avatar
      final create = await dio.post('/avatar', data: {'name': 'ダートぶた'}, options: auth);
      expect(create.statusCode, 201);
      expect(create.data['avatar']['name'], 'ダートぶた');

      // Get avatar
      final get = await dio.get('/avatar', options: auth);
      expect(get.statusCode, 200);
      expect(get.data['avatar']['stats']['hp'], 100);
    });
  });

  group('Battle/Social Flow', () {
    test('rankings + battle history', () async {
      final token = 'mock-token-dart-battle';
      final auth = Options(headers: {'Authorization': 'Bearer $token'});

      // Rankings
      final rankings = await dio.get('/rankings');
      expect(rankings.statusCode, 200);
      expect((rankings.data['rankings'] as List).length, greaterThan(0));

      // Battle history
      final history = await dio.get('/battles/history', options: auth);
      expect(history.statusCode, 200);
      expect((history.data['history'] as List).length, greaterThan(0));

      // Friends
      final friends = await dio.get('/social/friends', options: auth);
      expect(friends.statusCode, 200);
    });
  });
}
