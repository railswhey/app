import { Page } from '@playwright/test';
import { newUserPath, userSessionPath } from './routes';

let counter = 0;

export interface UserCredentials {
  username: string;
  email: string;
  password: string;
}

/**
 * Generate a unique user with timestamp + counter to avoid collisions
 * even when tests run in parallel.
 */
export function uniqueUser(): UserCredentials {
  const ts = Date.now();
  const n = ++counter;
  return {
    username: `user_${ts}_${n}`,
    email: `user_${ts}_${n}@example.com`,
    password: 'Password123!',
  };
}

/**
 * Sign up a new user via the /users/new form.
 * Waits for redirect to the app root after successful registration.
 */
export async function signUp(page: Page, user: UserCredentials): Promise<void> {
  await page.goto(newUserPath());
  await page.getByLabel('Username').fill(user.username);
  await page.getByLabel('Email address').fill(user.email);
  await page.getByPlaceholder('At least 8 characters').fill(user.password);
  await page.getByPlaceholder('Same again').fill(user.password);
  await page.getByRole('button', { name: /create account/i }).click();
  await page.waitForURL(/\/(task_lists|inbox|dashboard|$)/, { timeout: 10_000 });
}

/**
 * Sign in an existing user via the /users/session form.
 * Waits for redirect away from the login page.
 */
export async function signIn(page: Page, user: Pick<UserCredentials, 'email' | 'password'>): Promise<void> {
  await page.goto(userSessionPath());
  await page.getByLabel('Email address').fill(user.email);
  await page.getByLabel('Password').fill(user.password);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/\/(task_lists|inbox|dashboard|$)/, { timeout: 10_000 });
}

/**
 * Open sidebar navigation on mobile (clicks hamburger if visible).
 * No-op on desktop where the sidebar is always visible.
 */
export async function openNav(page: Page): Promise<void> {
  const hamburger = page.locator('button.hamburger');
  if (await hamburger.isVisible()) {
    await hamburger.click();
    await page.locator('body.nav-open').waitFor({ timeout: 3_000 });
  }
}

/**
 * Sign out by clicking the "Log out" link in the navigation.
 */
export async function signOut(page: Page): Promise<void> {
  await openNav(page);
  await page.getByRole('link', { name: /log out/i }).click();
  await page.waitForURL(/\/(users\/session|$)/, { timeout: 10_000 });
}
