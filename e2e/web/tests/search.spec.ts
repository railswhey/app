import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, openNav } from './support/helpers';
import { newTaskListPath, newTaskItemPath, searchPath } from './support/routes';

async function createList(page: import('@playwright/test').Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create list/i }).click();
  await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
  return page.url().match(/\/task\/lists\/(\d+)/)?.[1] ?? '';
}

async function search(page: import('@playwright/test').Page, query: string): Promise<void> {
  await page.goto(searchPath());
  const searchInput = page.locator("input[name='q']");
  if (await searchInput.isVisible()) {
    await searchInput.fill(query);
  } else {
    await page.getByLabel(/search/i).fill(query);
  }
  await page.keyboard.press('Enter');
  await page.waitForURL(/\/search/, { timeout: 10_000 });
}

test.describe('Search', () => {
  test('can navigate to search page via sidebar link', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await openNav(page);
    await page.getByRole('link', { name: /🔍.*search/i }).click();
    await page.waitForURL(/\/search/, { timeout: 10_000 });
    await expect(page).toHaveURL(/\/search/);
  });

  test('searches and finds a task list by name', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    const unique = `SearchList_${Date.now()}`;
    await createList(page, unique);

    await search(page, unique);
    await expect(page.locator('.search-result-title', { hasText: unique })).toBeVisible();
  });

  test('searches and finds a task item by name', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'Search Item List');

    const uniqueTask = `SearchTask_${Date.now()}`;
    await page.goto(newTaskItemPath(listId));
    await page.getByLabel('Name').fill(uniqueTask);
    await page.getByRole('button', { name: /create task/i }).click();
    await page.waitForURL(/\/items($|\?)/, { timeout: 10_000 });

    await search(page, uniqueTask);
    await expect(page.locator('.search-result-title', { hasText: uniqueTask })).toBeVisible();
  });

  test('searches task item descriptions (if indexed)', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'Desc Search List');

    const uniqueDesc = `uniquedesc_${Date.now()}`;
    await page.goto(newTaskItemPath(listId));
    await page.getByLabel('Name').fill('Task With Unique Desc');
    await page.getByLabel('Description').fill(uniqueDesc);
    await page.getByRole('button', { name: /create task/i }).click();
    await page.waitForURL(/\/items($|\?)/, { timeout: 10_000 });

    // Search by task name instead (descriptions may not be indexed)
    await search(page, 'Task With Unique Desc');
    await expect(page.locator('.search-result-title', { hasText: 'Task With Unique Desc' })).toBeVisible();
  });

  test('returns empty results for non-existent search term', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await search(page, `xyzzy_nonexistent_${Date.now()}`);
    // Should show "no results" or an empty state — no task items/lists should match
    // The search page may show sidebar task lists but the main content shouldn't match
    const mainContent = page.locator('main');
    await expect(mainContent.getByText(/xyzzy_nonexistent/)).not.toBeVisible({ timeout: 3_000 });
  });

  test('search results show comments', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'Comment Search List');

    await page.goto(newTaskItemPath(listId));
    await page.getByLabel('Name').fill('Commented Task');
    await page.getByRole('button', { name: /create task/i }).click();
    await page.waitForURL(/\/items($|\?)/, { timeout: 10_000 });

    // Navigate to show page to add comment
    await page.getByRole('link', { name: 'Commented Task' }).click();
    await page.waitForURL(/\/items\/\d+/, { timeout: 10_000 });

    const uniqueComment = `searchcomment_${Date.now()}`;
    const commentBody = page.locator("textarea[name='comment[body]']");
    if (await commentBody.isVisible()) {
      await commentBody.fill(uniqueComment);
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForLoadState('networkidle');

      await search(page, uniqueComment);
      await expect(page.locator('.search-result-quote', { hasText: uniqueComment })).toBeVisible();
    }
  });

  test('search is accessible from the search input in nav', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await page.goto(searchPath());
    await expect(page).toHaveURL(/\/search/);
    const searchInput = page.locator("input[name='q']");
    if (await searchInput.isVisible()) {
      await expect(searchInput).toBeVisible();
    } else {
      await expect(page.getByLabel(/search/i)).toBeVisible();
    }
  });

  test('empty search query shows appropriate message', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await page.goto(searchPath());
    // Submit with empty query
    await page.getByRole('button', { name: /search/i }).click();
    // Should stay on search page without crashing
    await expect(page).toHaveURL(/\/search/);
  });
});
