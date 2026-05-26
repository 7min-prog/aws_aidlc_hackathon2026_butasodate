import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  use: {
    baseURL: 'http://localhost:8085',
    viewport: { width: 390, height: 740 },
    actionTimeout: 10_000,
    headless: process.env.HEADED !== 'true',
  },
  webServer: {
    command: 'python -m http.server 8085 --directory ../build/web',
    port: 8085,
    reuseExistingServer: true,
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});
