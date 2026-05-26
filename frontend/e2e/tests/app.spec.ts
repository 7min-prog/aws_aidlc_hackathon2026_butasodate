import { test, expect } from '@playwright/test';
import { login, enableFlutterSemantics } from './helpers';

const TEST_EMAIL = process.env.E2E_EMAIL || '';
const TEST_PASSWORD = process.env.E2E_PASSWORD || '';

test.describe('Login flow', () => {
  test('shows login form', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);

    await expect(page.getByRole('textbox', { name: 'mail@example.com' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'パスワード' })).toBeVisible();
  });

  test('login button disabled when fields empty', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);

    await expect(page.getByRole('button', { name: 'ログイン', exact: true })).not.toBeVisible();
  });

  test('login button appears after filling fields', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);

    const email = page.getByRole('textbox', { name: 'mail@example.com' });
    await email.click();
    await email.pressSequentially('test@test.com', { delay: 20 });

    const pw = page.getByRole('textbox', { name: 'パスワード' });
    await pw.click();
    await pw.pressSequentially('password', { delay: 20 });

    await expect(page.getByRole('button', { name: 'ログイン', exact: true })).toBeVisible({ timeout: 3000 });
  });

  test('failed login stays on login page', async ({ page }) => {
    await page.goto('/#/login');
    await enableFlutterSemantics(page);

    const email = page.getByRole('textbox', { name: 'mail@example.com' });
    await email.click();
    await email.pressSequentially('wrong@test.com', { delay: 20 });

    const pw = page.getByRole('textbox', { name: 'パスワード' });
    await pw.click();
    await pw.pressSequentially('wrongpass', { delay: 20 });

    await page.getByRole('button', { name: 'ログイン', exact: true }).click();
    await page.waitForTimeout(5000);

    expect(page.url()).toContain('/login');
  });
});

test.describe('Authenticated flows', () => {
  test.skip(!TEST_EMAIL || !TEST_PASSWORD, 'E2E_EMAIL and E2E_PASSWORD env vars required');

  test.beforeEach(async ({ page }) => {
    await login(page, TEST_EMAIL, TEST_PASSWORD);
    // Wait for home screen to fully render
    await expect(page.getByRole('button', { name: 'ようすをみる' })).toBeVisible({ timeout: 10000 });
  });

  test('login navigates to home', async ({ page }) => {
    // Already verified in beforeEach
    expect(page.url()).toContain('/home');
  });

  test('home shows tab bar', async ({ page }) => {
    await expect(page.getByRole('button', { name: 'きろく' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'バトル' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'フレンド' }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'せってい' }).first()).toBeVisible();
  });

  test('navigate to recording tab', async ({ page }) => {
    await page.getByRole('button', { name: 'きろく' }).first().click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'きょう' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'きろくする' })).toBeVisible();
  });

  test('navigate to category select', async ({ page }) => {
    await page.getByRole('button', { name: 'きろく' }).first().click();
    await page.waitForTimeout(2000);
    await page.getByRole('button', { name: 'きろくする' }).click();
    await page.waitForTimeout(3000);
    await expect(page.getByRole('button', { name: /ラーメン|暴飲暴食|間食/ }).first()).toBeVisible();
  });

  test('navigate to battle tab', async ({ page }) => {
    await page.getByRole('button', { name: 'バトル' }).click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'ランダムマッチ' })).toBeVisible();
  });

  test('navigate to friend tab', async ({ page }) => {
    await page.getByRole('button', { name: 'フレンド' }).click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: '＋ ついか' })).toBeVisible();
  });

  test('navigate to settings', async ({ page }) => {
    await page.getByRole('button', { name: 'せってい' }).click();
    await page.waitForTimeout(2000);
    await expect(page.getByRole('button', { name: 'プロフィール' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'ログアウト' })).toBeVisible();
  });

  test('navigate to avatar detail', async ({ page }) => {
    await page.getByRole('button', { name: 'ようすをみる' }).click();
    await page.waitForTimeout(3000);
    await expect(page.getByRole('button', { name: 'しんか ずかん →' })).toBeVisible();
  });
});
