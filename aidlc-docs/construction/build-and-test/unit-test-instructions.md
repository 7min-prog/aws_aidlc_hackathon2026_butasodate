# Unit Test Execution

## テストフレームワーク追加（初回のみ）

```bash
cd backend/auth-handler
npm install --save-dev jest ts-jest @types/jest
```

`package.json` に追加:
```json
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage"
  },
  "jest": {
    "preset": "ts-jest",
    "testEnvironment": "node",
    "testMatch": ["**/tests/**/*.test.ts"]
  }
}
```

## テスト対象

| ハンドラー | テスト観点 |
|-----------|-----------|
| signup.ts | バリデーション、Cognito例外ハンドリング |
| login.ts | 認証成功/失敗、トークン返却 |
| logout.ts | アクセストークン検証 |
| refresh.ts | リフレッシュトークン検証 |
| profile.ts | ニックネームバリデーション、一意性チェック |

## Run Unit Tests

```bash
cd backend/auth-handler
npm test
```

## テスト作成方針

AWS SDKをモックして、ハンドラーのロジックのみをテスト:

```typescript
// tests/handlers/signup.test.ts の例
import { handleSignup } from '../../src/handlers/signup';

jest.mock('../../src/utils/cognito-client', () => ({
  cognitoClient: { send: jest.fn() },
  CLIENT_ID: 'test-client-id',
}));

describe('handleSignup', () => {
  it('should return 400 if email is missing', async () => {
    const event = { body: JSON.stringify({ password: 'Test1234!' }) } as any;
    const result = await handleSignup(event);
    expect(result.statusCode).toBe(400);
  });
});
```

## Expected Results
- 全テストがパス
- カバレッジ目標: 80%以上（ハッカソン向け）
