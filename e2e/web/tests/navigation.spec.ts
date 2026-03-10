import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, openNav } from './support/helpers';
import { taskListsPath } from './support/routes';

test.describe('Navigation & Layout', () => {
  test('sidebar shows all nav items', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await expect(page.locator('nav a', { hasText: 'Inbox' }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: '📋 Lists' })).toBeVisible();
    await expect(page.getByRole('link', { name: '👤 My Tasks' })).toBeVisible();
    await expect(page.getByRole('link', { name: /🔍 Search/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /🔔 Notifications/i }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: '⚙️ Settings' })).toBeVisible();
    await expect(page.getByRole('link', { name: /log out/i }).first()).toBeVisible();
  });

  test('account switcher shows current account name', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    await expect(page.locator('.account-switcher summary')).toContainText(user.username);
  });

  test('logo link navigates to inbox', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    // Navigate away from inbox
    await page.goto(taskListsPath());
    // Click the inbox link in nav (open sidebar first on mobile)
    await openNav(page);
    await page.locator('nav a', { hasText: 'Inbox' }).first().click();
    await page.waitForURL(/\/task_items/, { timeout: 10_000 });
  });
});
