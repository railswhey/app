/**
 * Documentation screenshot capture.
 *
 * Navigates through the entire app with a fresh user, builds up realistic
 * state, and saves PNG screenshots to docs/screenshots/.
 *
 * Run via:  mise run e2e:web:screenshots
 * Or:       cd e2e/web && npx playwright test tests/screenshots.spec.ts --project=chrome
 *
 * Requires a running server (mise run dev).
 */

import { test } from '@playwright/test';
import type { Page } from '@playwright/test';
import * as path from 'path';
import { uniqueUser, signUp, signOut } from './support/helpers';
import {
  newUserPath, userSessionPath, userPasswordPath,
  taskListsPath, newTaskListPath, taskItemsPath, newTaskItemPath,
  myTasksPath, searchPath, notificationsPath, settingsPath, userProfilePath,
  userTokenPath, apiDocsPath, apiDocsSectionPath,
} from './support/routes';

const SCREENSHOTS_DIR = path.join(__dirname, '../../../docs/screenshots');

async function shot(page: Page, filename: string): Promise<void> {
  await page.screenshot({
    path: path.join(SCREENSHOTS_DIR, filename),
    animations: 'disabled',
  });
}

// ── helpers (mirrors patterns from existing specs) ────────────────────────────

async function createList(page: Page, name: string, description = ''): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  if (description) await page.getByLabel('Description').fill(description);
  await page.getByRole('button', { name: /create task list/i }).click();
  await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
  return page.url().match(/\/task_lists\/(\d+)/)?.[1] ?? '';
}

async function createItem(page: Page, listId: string, name: string, description = ''): Promise<string> {
  await page.goto(newTaskItemPath(listId));
  await page.getByLabel('Name').fill(name);
  if (description) await page.getByLabel('Description').fill(description);
  await page.getByRole('button', { name: /create task item/i }).click();
  await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });
  const links = page.getByRole('link', { name });
  await links.first().waitFor({ timeout: 5_000 });
  return page.url();
}

// ── spec ──────────────────────────────────────────────────────────────────────

test('capture documentation screenshots', async ({ page }) => {
  const user = uniqueUser();

  // ── Sign in page ────────────────────────────────────────────────────────────
  await page.goto(userSessionPath());
  await page.getByLabel('Email address').waitFor();
  await shot(page, '001_sign_in.png');

  // ── Sign in error ───────────────────────────────────────────────────────────
  await page.getByLabel('Email address').fill('nobody@example.com');
  await page.getByLabel('Password').fill('wrong');
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/\/users\/session/, { timeout: 10_000 });
  await page.locator('.notice').waitFor({ timeout: 5_000 });
  await shot(page, '002_sign_in_error.png');

  // ── Sign up page ────────────────────────────────────────────────────────────
  await page.goto(newUserPath());
  await page.getByLabel('Username').waitFor();
  await shot(page, '003_sign_up.png');

  // ── Forgot password page ────────────────────────────────────────────────────
  await page.goto(userPasswordPath());
  await page.getByLabel('Email address').waitFor();
  await shot(page, '004_forgot_password.png');

  // ── Create account and set up state ────────────────────────────────────────
  await signUp(page, user);

  // ── Task lists ──────────────────────────────────────────────────────────────
  await page.goto(taskListsPath());
  await page.locator('main').waitFor();
  await shot(page, '010_task_lists.png');

  // ── New task list form ──────────────────────────────────────────────────────
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').waitFor();
  await shot(page, '011_new_task_list.png');

  // Create task list with content for later screenshots
  const workListId = await createList(page, 'Work', 'Work-related tasks');
  await shot(page, '012_task_list_created.png');

  // ── New task item form ──────────────────────────────────────────────────────
  await page.goto(newTaskItemPath(workListId));
  await page.getByLabel('Name').waitFor();
  await shot(page, '020_new_task_item.png');

  // Create several tasks to make the list look realistic
  await createItem(page, workListId, 'Write unit tests', 'Cover the new endpoints');
  await createItem(page, workListId, 'Review pull request');
  await createItem(page, workListId, 'Update documentation');

  // ── Task list with items ────────────────────────────────────────────────────
  await page.goto(taskItemsPath(workListId));
  await page.getByRole('link', { name: 'Write unit tests' }).waitFor();
  await shot(page, '021_task_items.png');

  // ── Task item show page ─────────────────────────────────────────────────────
  await page.getByRole('link', { name: 'Write unit tests' }).first().click();
  await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
  await shot(page, '022_task_item_show.png');

  // ── Complete a task ─────────────────────────────────────────────────────────
  await page.getByRole('link', { name: '✅ Complete' }).click();
  await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
  await page.getByRole('link', { name: '↩ Incomplete' }).waitFor();
  await shot(page, '023_task_item_completed.png');

  // ── Task list filtered by incomplete ───────────────────────────────────────
  await page.goto(`${taskItemsPath(workListId)}?filter=incomplete`);
  await page.locator('main').waitFor();
  await shot(page, '024_task_items_incomplete.png');

  // ── My Tasks ────────────────────────────────────────────────────────────────
  await page.goto(myTasksPath());
  await page.locator('main').waitFor();
  await shot(page, '030_my_tasks.png');

  // ── Search (empty) ──────────────────────────────────────────────────────────
  await page.goto(searchPath());
  await page.locator('main').waitFor();
  await shot(page, '040_search.png');

  // ── Search with results ─────────────────────────────────────────────────────
  const searchInput = page.locator("input[name='q']");
  await searchInput.fill('Write');
  await page.keyboard.press('Enter');
  await page.waitForURL(/\/search/, { timeout: 10_000 });
  await page.locator('main').waitFor();
  await shot(page, '041_search_results.png');

  // ── Notifications ───────────────────────────────────────────────────────────
  await page.goto(notificationsPath());
  await page.locator('main').waitFor();
  await shot(page, '050_notifications.png');

  // ── Settings hub ───────────────────────────────────────────────────────────
  await page.goto(settingsPath());
  await page.locator('main').waitFor();
  await shot(page, '060_settings.png');

  // ── Profile / change password ───────────────────────────────────────────────
  await page.goto(userProfilePath());
  await page.locator('main').waitFor();
  await shot(page, '061_settings_profile.png');

  // ── API token ───────────────────────────────────────────────────────────────
  await page.goto(userTokenPath());
  await page.locator('main').waitFor();
  await shot(page, '062_settings_token.png');

  // ── API docs overview ───────────────────────────────────────────────────────
  await page.goto(apiDocsPath());
  await page.locator('main').waitFor();
  await shot(page, '070_api_docs.png');

  // ── API docs — task lists section ──────────────────────────────────────────
  await page.goto(apiDocsSectionPath('task_lists'));
  await page.locator('main').waitFor();
  await shot(page, '071_api_docs_task_lists.png');
});
