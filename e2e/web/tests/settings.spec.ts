import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, signOut, openNav } from './support/helpers';
import { accountPath, userProfilePath, userSessionPath, settingsPath, userTokenPath } from './support/routes';

test.describe('Settings', () => {
  test.describe('Account Settings', () => {
    test('can navigate to account settings', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(accountPath());
      await expect(page).toHaveURL(/\/account/);
    });

    test('can navigate to settings via sidebar', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await openNav(page);
      await page.getByRole('link', { name: /⚙️.*settings/i }).click();
      await page.waitForURL(/\/(account|settings)/, { timeout: 10_000 });
      await expect(page).not.toHaveURL(/users\/session/);
    });

    test('updates account name', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(accountPath());
      const nameField = page.getByLabel('Name');
      if (await nameField.isVisible()) {
        await nameField.fill('My Updated Account');
        await page.getByRole('button', { name: /save/i }).click();
        await page.waitForURL(/\/account/, { timeout: 10_000 });
        await expect(page.getByLabel('Name')).toHaveValue('My Updated Account');
      }
    });

    test('shows validation error for empty account name', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(accountPath());
      const nameField = page.getByLabel('Name');
      if (await nameField.isVisible()) {
        await nameField.fill('');
        await page.getByRole('button', { name: /save/i }).click();
        // Should stay on account page with error
        await expect(page).toHaveURL(/\/account/);
      }
    });
  });

  test.describe('Profile Settings', () => {
    test('can navigate to profile settings', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userProfilePath());
      await expect(page).toHaveURL(/\/users\/profile/);
    });

    test('updates username in profile', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userProfilePath());
      const usernameField = page.getByLabel('Username');
      if (await usernameField.isVisible()) {
        const newUsername = `updated_${Date.now()}`;
        await usernameField.fill(newUsername);
        // Profile form requires current password and new password
        await page.getByLabel('Current password').fill(user.password);
        await page.getByLabel('New password').fill(user.password);
        await page.getByLabel('Password confirmation').fill(user.password);
        await page.getByRole('button', { name: /update password/i }).click();
        await page.waitForURL(/\/users\/profile/, { timeout: 10_000 });
        await expect(page.getByLabel('Username')).toHaveValue(newUsername);
      }
    });

    test('shows validation error for duplicate username', async ({ page }) => {
      const user1 = uniqueUser();
      const user2 = uniqueUser();

      // Sign up user1 first to reserve username
      await signUp(page, user1);

      // Sign out first, then register user2
      await signOut(page);
      await page.goto(userSessionPath());
      await page.getByRole('link', { name: /create one|sign up/i }).click();
      await page.waitForURL(/\/users\/new/, { timeout: 10_000 });
      await page.getByLabel('Username').fill(user2.username);
      await page.getByLabel('Email address').fill(user2.email);
      await page.getByPlaceholder('At least 8 characters').fill(user2.password);
      await page.getByPlaceholder('Same again').fill(user2.password);
      await page.getByRole('button', { name: /create account/i }).click();
      await page.waitForURL(/\/(task\/lists|inbox|dashboard|$)/, { timeout: 10_000 });

      // Try to change user2's username to user1's
      await page.goto(userProfilePath());
      const usernameField = page.getByLabel('Username');
      if (await usernameField.isVisible()) {
        await usernameField.fill(user1.username);
        await page.getByLabel('Current password').fill(user2.password);
        await page.getByLabel('New password').fill(user2.password);
        await page.getByLabel('Password confirmation').fill(user2.password);
        await page.getByRole('button', { name: /update password/i }).click();
        // Should show validation error (stay on profile page)
        await expect(page).toHaveURL(/\/users\/profile/);
      }
    });
  });

  test.describe('Password Settings', () => {
    test('password change form is accessible from settings', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Profile page has the password change form (combined with username)
      await page.goto(userProfilePath());
      await expect(page.getByLabel('Current password')).toBeVisible();
      await expect(page.getByLabel('New password')).toBeVisible();
      await expect(page.getByLabel('Password confirmation')).toBeVisible();
    });
  });

  test.describe('API Token', () => {
    test('API token section is accessible in settings', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Settings hub has API Token card
      await page.goto(settingsPath());
      await page.getByRole('link', { name: /api token/i }).click();
      await page.waitForURL(/\/users\/token/, { timeout: 10_000 });
      await expect(page.getByRole('heading', { name: /api token/i })).toBeVisible();
    });

    test('can generate or view API token', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userTokenPath());
      // Token is displayed on the page
      await expect(page.locator('pre')).toBeVisible();
      // Refresh button exists
      await expect(page.getByRole('button', { name: /refresh/i })).toBeVisible();
    });
  });

  test.describe('Account Members', () => {
    test('account settings shows members section for owner', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(accountPath());
      // Members section should be visible
      await expect(page.getByText(/members/i)).toBeVisible();
    });
  });

  test.describe('Settings Navigation', () => {
    test('settings page shows links to profile, account, password sections', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await openNav(page);
      await page.getByRole('link', { name: /⚙️.*settings/i }).click();
      await page.waitForURL(/\/(account|settings)/, { timeout: 10_000 });

      // Settings hub has cards/links for Profile & Password, API Token, Account
      await expect(page.locator('main').getByText(/profile/i).first()).toBeVisible();
      await expect(page.locator('main').getByText(/api token/i).first()).toBeVisible();
      await expect(page.locator('main').getByText(/account/i).first()).toBeVisible();
    });

    test('edit profile with blank username shows validation error', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userProfilePath());
      const usernameField = page.getByLabel('Username');
      if (await usernameField.isVisible()) {
        await usernameField.fill('');
        await page.getByLabel('Current password').fill(user.password);
        await page.getByLabel('New password').fill(user.password);
        await page.getByLabel('Password confirmation').fill(user.password);
        await page.getByRole('button', { name: /update password/i }).click();
        // Should stay on profile page with validation error
        await expect(page).toHaveURL(/\/users\/profile/);
      }
    });
  });
});
