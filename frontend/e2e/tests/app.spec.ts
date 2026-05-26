import { test, expect, Page } from '@playwright/test';
import { login, enableFlutterSemantics } from './helpers';

const TEST_EMAIL = process.env.E2E_EMAIL || '';
const TEST_PASSWORD = process.env.E2E_PASSWORD || '';

/** Navigate to settings tab from home */
async function goToSettings(page: Page) {
  await page.getByRole('button', { name: 'せってい' }).first().click();
  await page.waitForTimeout(2000);
}

// ============================================================
// X: 起動系画面 (LAUNCH)
// ============================================================
test.describe('X: Launch screens', () => {
  test('X-00 Start screen renders', async ({ page }) => {
    await page.goto('/#/start');
    await enableFlutterSemantics(page);
    await expect(page.locator('flt-semantics[role="button"]').first()).toBeVisible();
  });

  test('X-03 Error screen renders', async ({ page }) => {
    await page.goto('/#/error');
    await enableFlutterSemantics(page);
    await expect(page.getByRole('button', { name: /リトライ|もういちど/ })).toBeVisible();
  });

  test('X-04 Maintenance screen renders', async ({ page }) => {
    await page.goto('/#/maintenance');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(1000);
    // Just verify it doesn't crash
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('X-05 Force update screen renders', async ({ page }) => {
    await page.goto('/#/force-update');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(1000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('X-06 Tutorial screen renders', async ({ page }) => {
    await page.goto('/#/tutorial');
    await enableFlutterSemantics(page);
    await expect(page.locator('flt-semantics[role="button"]').first()).toBeVisible();
  });
});

// ============================================================
// A: 認証フロー (AUTH)
// ============================================================
test.describe('A: Auth flow', () => {
  test('A-01 Login form elements', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);
    await expect(page.getByRole('textbox', { name: 'mail@example.com' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'パスワード' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Google で ログイン' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'X で ログイン' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'アカウントを つくる →' })).toBeVisible();
    await expect(page.getByRole('button', { name: '利用規約' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'プライバシーポリシー' })).toBeVisible();
  });

  test('A-01 Login button hidden when empty', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);
    await expect(page.getByRole('button', { name: 'ログイン', exact: true })).not.toBeVisible();
  });

  test('A-01 Login button visible after input', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);
    const email = page.getByRole('textbox', { name: 'mail@example.com' });
    await email.click();
    await email.pressSequentially('a@b.com', { delay: 20 });
    const pw = page.getByRole('textbox', { name: 'パスワード' });
    await pw.click();
    await pw.pressSequentially('pass', { delay: 20 });
    await expect(page.getByRole('button', { name: 'ログイン', exact: true })).toBeVisible({ timeout: 3000 });
  });

  test('A-01 Failed login stays on login', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);
    const email = page.getByRole('textbox', { name: 'mail@example.com' });
    await email.click();
    await email.pressSequentially('wrong@x.com', { delay: 20 });
    const pw = page.getByRole('textbox', { name: 'パスワード' });
    await pw.click();
    await pw.pressSequentially('bad', { delay: 20 });
    await page.getByRole('button', { name: 'ログイン', exact: true }).click();
    await page.waitForTimeout(5000);
    // Still on login - email field still visible (or error dialog shown)
    expect(page.url()).toContain('/login');
  });

  test('A-02 Signup screen renders', async ({ page }) => {
    await page.goto('/#/signup');
    await enableFlutterSemantics(page);
    await expect(page.getByRole('textbox', { name: 'mail@example.com' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'パスワード' })).toBeVisible();
  });

  test('L-01 Terms screen renders', async ({ page }) => {
    await page.goto('/#/terms');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(1000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('L-02 Privacy screen renders', async ({ page }) => {
    await page.goto('/#/privacy');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(1000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });
});

// ============================================================
// Authenticated tests
// ============================================================
test.describe('Authenticated flows', () => {
  test.skip(!TEST_EMAIL || !TEST_PASSWORD, 'E2E_EMAIL and E2E_PASSWORD required');

  test.beforeEach(async ({ page }) => {
    await login(page, TEST_EMAIL, TEST_PASSWORD);
    await expect(page.getByRole('button', { name: 'ようすをみる' })).toBeVisible({ timeout: 10000 });
  });

  // M: メインタブ
  test('M-01 Home shows avatar and tabs', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'ようすをみる' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'きろく' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'バトル' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'フレンド' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'せってい' }).first()).toBeVisible();
  });

  test('M-02 Recording tab', async ({ page }) => {
    await page.getByRole('button', { name: 'きろく' }).first().click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'きょう' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'しゅう' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'つき' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'きろくする' })).toBeVisible();
  });

  test('M-03 Battle tab', async ({ page }) => {
    await page.getByRole('button', { name: 'バトル' }).first().click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'ランダムマッチ' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'フレンド たいせん' })).toBeVisible();
  });

  test('M-04 Friend tab', async ({ page }) => {
    await page.getByRole('button', { name: 'フレンド' }).first().click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: '＋ ついか' })).toBeVisible();
  });

  test('M-05 Settings tab', async ({ page }) => {
    await goToSettings(page);
    await expect(page.getByRole('button', { name: 'プロフィール' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'おしらせ' })).toBeVisible();
    await expect(page.getByRole('button', { name: /ヘルスケア/ })).toBeVisible();
    await expect(page.getByRole('button', { name: 'ライセンス' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'ログアウト' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'アカウント削除' })).toBeVisible();
  });

  // R: 記録フロー
  test('R-01 Category select from API', async ({ page }) => {
    await page.goto('/#/record-category');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(3000);
    await expect(page.getByRole('button', { name: /深夜ラーメン/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /暴飲暴食/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /間食/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /夜更かし/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /運動サボり/ })).toBeVisible();
  });

  test('R-02 Record confirm screen', async ({ page }) => {
    await page.goto('/#/record-category');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(3000);
    await page.getByRole('button', { name: /深夜ラーメン/ }).click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'きろくする' })).toBeVisible();
  });

  test('R-03 Record complete screen', async ({ page }) => {
    await page.goto('/#/record-complete');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  // V: アバター
  test('V-01 Avatar detail', async ({ page }) => {
    await page.getByRole('button', { name: 'ようすをみる' }).click();
    await page.waitForTimeout(3000);
    await expect(page.getByRole('button', { name: 'しんか ずかん →' })).toBeVisible();
  });

  test('V-03 Evo book', async ({ page }) => {
    await page.goto('/#/evo-book');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(3000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  // S: ソーシャル
  test('S-02 Friend search', async ({ page }) => {
    await page.goto('/#/friend-search');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.getByRole('textbox').first()).toBeVisible();
  });

  test('S-03 Battle history', async ({ page }) => {
    await page.goto('/#/battle-history');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  // T: アカウント設定
  test('T-01 Profile edit', async ({ page }) => {
    await page.goto('/#/profile-edit');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.getByRole('textbox').first()).toBeVisible();
  });

  test('T-02 Health data', async ({ page }) => {
    await page.goto('/#/health-data');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('T-03 Notification settings', async ({ page }) => {
    await page.goto('/#/notification-settings');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  // L: 法務
  test('L-04 License list', async ({ page }) => {
    await page.goto('/#/licenses');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('L-03 Health consent', async ({ page }) => {
    await page.goto('/#/health-consent');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  test('L-05 Commercial law', async ({ page }) => {
    await page.goto('/#/commercial-law');
    await enableFlutterSemantics(page);
    await page.waitForTimeout(2000);
    await expect(page.locator('flt-semantics').first()).toBeVisible();
  });

  // D: ダイアログ
  test('D-01 Logout dialog', async ({ page }) => {
    await goToSettings(page);
    await page.getByRole('button', { name: 'ログアウト' }).click();
    await page.waitForTimeout(1000);
    // Verify dialog appeared (new buttons visible)
    const buttons = await page.getByRole('button').allTextContents();
    expect(buttons.some(b => /はい|ログアウト/.test(b))).toBeTruthy();
  });

  test('D-02 Account delete dialog', async ({ page }) => {
    await goToSettings(page);
    await page.getByRole('button', { name: 'アカウント削除' }).click();
    await page.waitForTimeout(1000);
    const buttons = await page.getByRole('button').allTextContents();
    expect(buttons.some(b => /さくじょ|やめる/.test(b))).toBeTruthy();
  });
});
