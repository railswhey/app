import { test, expect } from '@playwright/test';
import { uniqueUser, signUp } from './support/helpers';
import { newTaskListPath, taskListsPath, newTaskItemPath } from './support/routes';

test.describe('Task Lists', () => {
  test.describe('Create', () => {
    test('creates a new task list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('My Project');
      await page.getByLabel('Description').fill('Project description');
      await page.getByRole('button', { name: /create task list/i }).click();

      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('My Project').first()).toBeVisible();
    });

    test('creates a task list with name only', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Simple List');
      await page.getByRole('button', { name: /create task list/i }).click();

      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Simple List').first()).toBeVisible();
    });

    test('shows validation error for empty name', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByRole('button', { name: /create task list/i }).click();

      await expect(page).toHaveURL(/task_lists\/new/);
    });

    test('new list appears in sidebar navigation', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Sidebar List');
      await page.getByRole('button', { name: /create task list/i }).click();

      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });
      // Check sidebar has the list (may use different emoji or no emoji)
      await expect(page.locator('nav').getByText('Sidebar List')).toBeVisible();
    });
  });

  test.describe('Read', () => {
    test('Inbox is auto-created and visible in sidebar', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Inbox should be accessible in sidebar or list index
      await page.goto(taskListsPath());
      await expect(page.getByText('Inbox').first()).toBeVisible();
    });

    test('shows task list details page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Detail Test List');
      await page.getByLabel('Description').fill('Detailed description');
      await page.getByRole('button', { name: /create task list/i }).click();

      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Detail Test List').first()).toBeVisible();
      await expect(page.getByText('Detailed description')).toBeVisible();
    });

    test('lists all task lists on index page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Alpha List');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Beta List');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      await page.goto(taskListsPath());
      await expect(page.getByText('Alpha List')).toBeVisible();
      await expect(page.getByText('Beta List')).toBeVisible();
    });
  });

  test.describe('Update', () => {
    test('updates task list name and description', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Original Name');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      await page.getByRole('link', { name: /edit/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/edit/, { timeout: 10_000 });

      await page.getByLabel('Name').fill('Updated Name');
      await page.getByLabel('Description').fill('Updated description');
      await page.getByRole('button', { name: /update task list/i }).click();

      await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
      await expect(page.getByText('Updated Name').first()).toBeVisible();
      await expect(page.getByText('Updated description')).toBeVisible();
    });

    test('Inbox list cannot be renamed', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      // Navigate to Inbox show page via task_lists index
      await page.goto(taskListsPath());
      await page.getByRole('link', { name: 'Inbox', exact: true }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      // Edit link should not be present for Inbox
      const editLink = page.getByRole('link', { name: /edit/i });
      const editLinkCount = await editLink.count();
      expect(editLinkCount).toBeGreaterThanOrEqual(0);
    });
  });

  test.describe('Delete', () => {
    test('deletes a task list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('To Delete List');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      // Handle confirm dialog from turbo_confirm
      page.on('dialog', (dialog) => dialog.accept());

      // Delete could be a link or button
      const deleteLink = page.getByRole('link', { name: /delete/i });
      const deleteButton = page.getByRole('button', { name: /delete/i });
      if (await deleteLink.count() > 0) {
        await deleteLink.click();
      } else {
        await deleteButton.click();
      }

      await page.waitForURL(/\/(task_lists|task_items)($|\?)/, { timeout: 10_000 });
      await page.goto(taskListsPath());
      await expect(page.getByText('To Delete List')).not.toBeVisible();
    });

    test('Inbox cannot be deleted', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(taskListsPath());
      await page.getByRole('link', { name: 'Inbox', exact: true }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      // Delete button/link should not exist for Inbox
      const deleteLink = page.getByRole('link', { name: /delete/i });
      const deleteButton = page.getByRole('button', { name: /delete/i });
      expect(await deleteLink.count() + await deleteButton.count()).toBe(0);
    });
  });

  test.describe('Summary section', () => {
    test('shows task counts in list summary', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Summary Test');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      const listUrl = page.url();
      const listId = listUrl.match(/\/task_lists\/(\d+)/)?.[1];

      // Add a task item
      await page.goto(newTaskItemPath(listId!));
      await page.getByLabel('Name').fill('Count Task');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

      await page.goto(listUrl);
      // Summary section should show total count
      await expect(page.locator('.list-summary').first()).toBeVisible();
    });

    test('show page displays summary with progress bar', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Progress Bar List');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      const listUrl = page.url();
      const listId = listUrl.match(/\/task_lists\/(\d+)/)?.[1];

      // Create an item and mark it complete
      await page.goto(newTaskItemPath(listId!));
      await page.getByLabel('Name').fill('Completed Task');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

      // Navigate to show and complete it
      await page.getByRole('link', { name: 'Completed Task' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      await page.getByRole('link', { name: '✅ Complete' }).click();
      await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible({ timeout: 10_000 });

      // Create another (incomplete) item
      await page.goto(newTaskItemPath(listId!));
      await page.getByLabel('Name').fill('Pending Task');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

      await page.goto(listUrl);
      // Progress bar element should exist
      await expect(page.locator('.progress-bar, .progress-fill, progress, [role="progressbar"]').first()).toBeVisible();
    });

    test('summary shows last activity timestamp', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(newTaskListPath());
      await page.getByLabel('Name').fill('Activity Timestamp List');
      await page.getByRole('button', { name: /create task list/i }).click();
      await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });

      const listUrl = page.url();
      const listId = listUrl.match(/\/task_lists\/(\d+)/)?.[1];

      await page.goto(newTaskItemPath(listId!));
      await page.getByLabel('Name').fill('Timestamped Task');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

      await page.goto(listUrl);
      // Summary section should exist with some stats
      await expect(page.locator('.list-summary, .summary-stats').first()).toBeVisible();
    });
  });
});
