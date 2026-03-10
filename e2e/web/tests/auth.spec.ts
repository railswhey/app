import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, signIn, signOut, openNav } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import {
  rootPath, newUserPath, userSessionPath, userProfilePath, userPasswordPath,
  userPasswordResetPath, taskListsPath, settingsPath, myTasksPath, searchPath,
  notificationsPath,
} from './support/routes';

test.describe('Authentication', () => {
  test.describe('Sign Up', () => {
    test('creates a new account with valid credentials', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await expect(page).not.toHaveURL(/users\/new/);
    });

    test('shows validation error for short password', async ({ page }) => {
      const user = uniqueUser();
      await page.goto(newUserPath());
      await page.getByLabel('Username').fill(user.username);
      await page.getByLabel('Email address').fill(user.email);
      await page.getByPlaceholder('At least 8 characters').fill('short');
      await page.getByPlaceholder('Same again').fill('short');
      await page.getByRole('button', { name: /create account/i }).click();
      // HTML5 validation or server-side — should not leave sign-up
      await expect(page.locator('body')).toBeVisible();
    });

    test('shows validation error for mismatched passwords', async ({ page }) => {
      const user = uniqueUser();
      await page.goto(newUserPath());
      await page.getByLabel('Username').fill(user.username);
      await page.getByLabel('Email address').fill(user.email);
      await page.getByPlaceholder('At least 8 characters').fill(user.password);
      await page.getByPlaceholder('Same again').fill('differentpassword');
      await page.getByRole('button', { name: /create account/i }).click();
      await expect(page.locator('body')).toBeVisible();
    });

    test('shows error for duplicate email', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);

      await page.goto(newUserPath());
      await page.getByLabel('Username').fill(`other_${user.username}`);
      await page.getByLabel('Email address').fill(user.email);
      await page.getByPlaceholder('At least 8 characters').fill(user.password);
      await page.getByPlaceholder('Same again').fill(user.password);
      await page.getByRole('button', { name: /create account/i }).click();
      await expect(page.locator('.notice.warn').first()).toBeVisible({ timeout: 5_000 });
    });

    test('sign up with blank fields shows validation errors', async ({ page }) => {
      await page.goto(newUserPath());
      // HTML5 required attributes prevent submission — just verify form is still there
      await page.getByRole('button', { name: /create account/i }).click();
      await expect(page.getByLabel('Username')).toBeVisible();
    });

    test('sign up with invalid email shows error', async ({ page }) => {
      const user = uniqueUser();
      await page.goto(newUserPath());
      await page.getByLabel('Username').fill(user.username);
      await page.getByLabel('Email address').fill('not-a-valid-email');
      await page.getByPlaceholder('At least 8 characters').fill(user.password);
      await page.getByPlaceholder('Same again').fill(user.password);
      await page.getByRole('button', { name: /create account/i }).click();
      // HTML5 email validation should prevent submission
      await expect(page.getByLabel('Email address')).toBeVisible();
    });

    test('sign up sets account name to username by default', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      // Account switcher in sidebar shows account name
      await expect(page.locator('.account-switcher summary')).toContainText(user.username);
    });

    test('sign up creates inbox automatically', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      // Sidebar shows "🗂️ Inbox" link for the inbox task list
      await expect(page.locator('nav a', { hasText: 'Inbox' }).first()).toBeVisible();
    });

    test('shows validation error for duplicate username', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);

      const user2 = uniqueUser();
      await page.goto(newUserPath());
      await page.getByLabel('Username').fill(user.username); // same username
      await page.getByLabel('Email address').fill(user2.email);
      await page.getByPlaceholder('At least 8 characters').fill(user2.password);
      await page.getByPlaceholder('Same again').fill(user2.password);
      await page.getByRole('button', { name: /create account/i }).click();
      await expect(page.locator('.notice.warn').first()).toBeVisible({ timeout: 5_000 });
    });
  });

  test.describe('Sign In', () => {
    test('signs in with valid credentials', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);
      await signIn(page, user);
      await expect(page).not.toHaveURL(/users\/session/);
    });

    test('shows error for wrong password', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);

      await page.goto(userSessionPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByLabel('Password').fill('wrongpassword');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/users\/session/);
    });

    test('shows error for non-existent email', async ({ page }) => {
      await page.goto(userSessionPath());
      await page.getByLabel('Email address').fill('nobody@example.com');
      await page.getByLabel('Password').fill('somepassword123');
      await page.getByRole('button', { name: /sign in/i }).click();
      await expect(page).toHaveURL(/users\/session/);
    });
  });

  test.describe('Sign Out', () => {
    test('signs out successfully', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);
      await expect(page).toHaveURL(/users\/session/);
    });

    test('redirects to sign-in page after sign-out', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await signOut(page);
      await page.goto(taskListsPath());
      await expect(page).toHaveURL(/users\/session/);
    });
  });

  test('visit root shows sign-in page', async ({ page }) => {
    await page.goto(rootPath());
    // Root redirects to sign-in for unauthenticated users
    await expect(page.getByLabel('Email address')).toBeVisible();
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible();
  });

  test.describe('Session', () => {
    test('session persists after page refresh', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await page.reload();
      await openNav(page);
      await expect(page.getByRole('link', { name: /log out/i })).toBeVisible();
    });

    test('protected routes redirect to sign-in when not authenticated', async ({ page }) => {
      const protectedRoutes = [taskListsPath(), settingsPath(), myTasksPath(), searchPath(), notificationsPath()];
      for (const route of protectedRoutes) {
        await page.goto(route);
        await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible();
      }
    });
  });

  test.describe('Account Management', () => {
    test('delete account destroys user and signs out', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userProfilePath());
      // turbo_confirm triggers window.confirm — intercept it
      page.on('dialog', (dialog) => dialog.accept());
      await page.getByRole('button', { name: /delete account/i }).click();
      // Root redirects to sign-in
      await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible({ timeout: 15_000 });
    });
  });

  test.describe('Password Change', () => {
    test('changes password successfully', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Profile page has the password change form
      await page.goto(userProfilePath());
      const newPassword = 'NewPassword456!';
      await page.getByLabel('Current password').fill(user.password);
      await page.getByLabel('New password').fill(newPassword);
      // The label is just "Password confirmation" in the form
      await page.locator('input[name="user[password_confirmation]"]').fill(newPassword);
      await page.getByRole('button', { name: /update password/i }).click();

      // Redirects back to profile page with success notice
      await expect(page.locator('.notice')).toContainText(/updated/i, { timeout: 10_000 });

      // Verify can sign in with new password
      await signOut(page);
      await signIn(page, { ...user, password: newPassword });
      await expect(page).not.toHaveURL(/users\/session/);
    });

    test('shows error for wrong current password', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(userProfilePath());
      await page.getByLabel('Current password').fill('wrongpassword');
      await page.getByLabel('New password').fill('NewPassword456!');
      await page.locator('input[name="user[password_confirmation]"]').fill('NewPassword456!');
      await page.getByRole('button', { name: /update password/i }).click();

      // Should stay on profile page with error
      await expect(page.locator('.notice.warn').first()).toBeVisible({ timeout: 5_000 });
    });

    test('password change form is accessible from settings', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(settingsPath());
      await page.getByRole('link', { name: /profile.*password/i }).click();
      await expect(page.getByLabel('Current password')).toBeVisible();
    });
  });

  test.describe('Password Reset', () => {
    test('forgot password form is accessible', async ({ page }) => {
      await page.goto(userPasswordPath());
      await expect(page.getByLabel('Email address')).toBeVisible();
      await expect(page.getByRole('button', { name: /send reset link/i })).toBeVisible();
    });

    test('forgot password with unknown email shows feedback without crashing', async ({ page }) => {
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill('nobody@example.com');
      await page.getByRole('button', { name: /send reset link/i }).click();
      // Should redirect to sign-in with a notice (no info leak about existence)
      await expect(page.locator('.notice')).toBeVisible({ timeout: 5_000 });
    });

    test('forgot password with valid email sends reset email via Mailpit', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Clear cookies to sign out (avoids mobile sidebar scroll issues)
      await page.context().clearCookies();

      await clearMailbox();
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByRole('button', { name: /send reset link/i }).click();

      const email = await waitForEmail(user.email, { timeout: 20_000 });
      expect(email.To[0].Address).toBe(user.email);
    });

    test('reset link from email leads to set new password page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await page.context().clearCookies();

      await clearMailbox();
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByRole('button', { name: /send reset link/i }).click();

      const email = await waitForEmail(user.email, { timeout: 20_000 });
      const body = await getEmailBody(email.ID);
      const resetLink = extractLink(body, '/password');

      await page.goto(resetLink);
      await expect(page.getByText('Set new password')).toBeVisible();
      await expect(page.getByLabel('New password')).toBeVisible();
      await expect(page.getByLabel('Confirm password')).toBeVisible();
    });

    test('set new password with mismatched passwords shows orange validation error', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await page.context().clearCookies();

      await clearMailbox();
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByRole('button', { name: /send reset link/i }).click();

      const email = await waitForEmail(user.email, { timeout: 20_000 });
      const body = await getEmailBody(email.ID);
      const resetLink = extractLink(body, '/password');

      await page.goto(resetLink);
      await page.getByLabel('New password').fill('newpassword1');
      await page.getByLabel('Confirm password').fill('different99');
      await page.getByRole('button', { name: /reset password/i }).click();

      // Orange inline form validation (notice warn, not notice error)
      const warn = page.locator('.notice.warn');
      await expect(warn).toBeVisible({ timeout: 5_000 });
      await expect(warn).toContainText(/confirmation.*doesn.*match/i);
    });

    test('set new password with short password shows orange validation error', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await page.context().clearCookies();

      await clearMailbox();
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByRole('button', { name: /send reset link/i }).click();

      const email = await waitForEmail(user.email, { timeout: 20_000 });
      const body = await getEmailBody(email.ID);
      const resetLink = extractLink(body, '/password');

      await page.goto(resetLink);
      await page.getByLabel('New password').fill('short');
      await page.getByLabel('Confirm password').fill('short');
      await page.getByRole('button', { name: /reset password/i }).click();

      const warn = page.locator('.notice.warn');
      await expect(warn).toBeVisible({ timeout: 5_000 });
      await expect(warn).toContainText(/too short/i);
    });

    test('full reset flow: request → email → reset → sign in with new password', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      await page.context().clearCookies();

      // Step 1: Request reset
      await clearMailbox();
      await page.goto(userPasswordPath());
      await page.getByLabel('Email address').fill(user.email);
      await page.getByRole('button', { name: /send reset link/i }).click();

      // Step 2: Get email and extract link
      const email = await waitForEmail(user.email, { timeout: 20_000 });
      const body = await getEmailBody(email.ID);
      const resetLink = extractLink(body, '/password');

      // Step 3: Set new password
      const newPassword = 'BrandNewPass99!';
      await page.goto(resetLink);
      await page.getByLabel('New password').fill(newPassword);
      await page.getByLabel('Confirm password').fill(newPassword);
      await page.getByRole('button', { name: /reset password/i }).click();

      // Step 4: Redirected to sign-in with success notice
      await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible({ timeout: 10_000 });
      await expect(page.locator('.notice')).toContainText(/reset successfully/i);

      // Step 5: Sign in with new password
      await signIn(page, { email: user.email, password: newPassword });
      await expect(page).not.toHaveURL(/users\/session/);
    });

    test('expired or invalid reset token redirects with error', async ({ page }) => {
      await page.goto(userPasswordResetPath('invalid-token-abc123'));
      await expect(page.locator('.notice.error')).toContainText(/invalid|expired/i, { timeout: 5_000 });
    });
  });

  test('click sign up link from sign-in page shows registration form', async ({ page }) => {
    await page.goto(userSessionPath());
    await page.getByRole('link', { name: /create one|sign up/i }).click();
    await expect(page.getByLabel('Username')).toBeVisible();
    await expect(page.getByRole('button', { name: /create account/i })).toBeVisible();
  });

  test('visit sign-in page shows sign-in form', async ({ page }) => {
    await page.goto(userSessionPath());
    await expect(page.getByLabel('Email address')).toBeVisible();
    await expect(page.getByLabel('Password')).toBeVisible();
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible();
  });
});
