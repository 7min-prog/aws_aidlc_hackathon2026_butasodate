import { Page, expect } from '@playwright/test';

/** Enable Flutter web accessibility semantics and wait for render */
export async function enableFlutterSemantics(page: Page) {
  await page.waitForTimeout(2000);
  await page.evaluate(() => {
    (document.querySelector('flt-semantics-placeholder') as HTMLElement)?.click();
  });
  await page.waitForTimeout(1000);
}

/** Fill a Flutter textbox by clicking then typing (fill() doesn't trigger Flutter's listeners) */
async function flutterFill(page: Page, locator: ReturnType<Page['getByRole']>, value: string) {
  await locator.click();
  await page.waitForTimeout(200);
  await locator.pressSequentially(value, { delay: 20 });
  await page.waitForTimeout(200);
}

/** Login helper */
export async function login(page: Page, email: string, password: string) {
  await page.goto('/#/login');
  await enableFlutterSemantics(page);

  // Fill email
  await flutterFill(page, page.getByRole('textbox', { name: 'mail@example.com' }), email);

  // Fill password
  await flutterFill(page, page.getByRole('textbox', { name: 'パスワード' }), password);

  // Wait for login button to appear (enabled after both fields filled)
  const loginBtn = page.getByRole('button', { name: 'ログイン', exact: true });
  await expect(loginBtn).toBeVisible({ timeout: 5000 });
  await loginBtn.click();

  // Wait for navigation
  await page.waitForTimeout(5000);
}
