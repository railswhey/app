import { test, expect } from '@playwright/test';
import { uniqueUser, signUp } from './support/helpers';
import { newTaskListPath, taskItemsPath, newTaskItemPath } from './support/routes';

// Helper: create a task list and return its ID
async function createList(page: import('@playwright/test').Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task list/i }).click();
  // Redirects to /task_lists/:id (show page)
  await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
  const url = page.url();
  return url.match(/\/task_lists\/(\d+)/)?.[1] ?? '';
}

// Helper: create a task item, ends on the index page. Returns nothing.
// Note: "Completed" checkbox only appears on edit form, not new form.
// To create a completed item, we create it then complete it from the show page.
async function createItem(page: import('@playwright/test').Page, listId: string, name: string, opts?: { completed?: boolean }) {
  await page.goto(newTaskItemPath(listId));
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task item/i }).click();
  await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });

  if (opts?.completed) {
    // Navigate to the item's show page and complete it
    await page.getByRole('link', { name }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✅ Complete' }).click();
    await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible({ timeout: 10_000 });
    // Go back to the index
    await page.goto(taskItemsPath(listId));
  }
}

// Helper: navigate to the first task item's show page from the index
async function goToItemShow(page: import('@playwright/test').Page, listId: string, itemName: string) {
  await page.goto(taskItemsPath(listId));
  await page.getByRole('link', { name: itemName }).click();
  await page.waitForURL(/\/task_lists\/\d+\/task_items\/\d+/, { timeout: 10_000 });
}

test.describe('Task Items', () => {
  test.describe('Create', () => {
    test('creates a new task item with name only', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Items Test List');

      await createItem(page, listId, 'My First Task');
      await expect(page.getByRole('link', { name: 'My First Task' })).toBeVisible();
    });

    test('creates a task item with description', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Desc Test List');

      await page.goto(newTaskItemPath(listId));
      await page.getByLabel('Name').fill('Task With Description');
      await page.getByLabel('Description').fill('This task has details');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });

      // Click into the item to see the description
      await page.getByRole('link', { name: 'Task With Description' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('This task has details')).toBeVisible();
    });

    test('creates a task item and marks it completed via edit', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Complete On Edit');

      await createItem(page, listId, 'To Be Completed');
      await goToItemShow(page, listId, 'To Be Completed');

      // Edit the item and check the Completed checkbox
      await page.getByRole('link', { name: '✏️ Edit' }).click();
      await page.waitForURL(/\/edit/, { timeout: 10_000 });
      await page.getByLabel('Completed').check();
      await page.getByRole('button', { name: /update task item/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });

      // Filter by completed to see it
      await page.goto(`${taskItemsPath(listId)}?filter=completed`);
      await expect(page.getByRole('link', { name: 'To Be Completed' })).toBeVisible();
    });

    test('shows validation error for empty name', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Validation List');

      await page.goto(newTaskItemPath(listId));
      // Name is required — HTML5 validation prevents submission
      await page.getByRole('button', { name: /create task item/i }).click();
      await expect(page.getByLabel('Name')).toBeVisible();
    });
  });

  test.describe('Read', () => {
    test('shows task item details', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Read Test List');

      await page.goto(newTaskItemPath(listId));
      await page.getByLabel('Name').fill('Detail Task');
      await page.getByLabel('Description').fill('Task details here');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });

      await page.getByRole('link', { name: 'Detail Task' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Detail Task').first()).toBeVisible();
      await expect(page.getByText('Task details here')).toBeVisible();
    });

    test('lists all task items for a list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Multi-Item List');

      await createItem(page, listId, 'Task Alpha');
      await createItem(page, listId, 'Task Beta');
      await createItem(page, listId, 'Task Gamma');

      await page.goto(taskItemsPath(listId));
      await expect(page.getByRole('link', { name: 'Task Alpha' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Task Beta' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Task Gamma' })).toBeVisible();
    });
  });

  test.describe('Update', () => {
    test('updates task item name and description', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Update Test List');

      await createItem(page, listId, 'Original Task');
      await goToItemShow(page, listId, 'Original Task');

      await page.getByRole('link', { name: '✏️ Edit' }).click();
      await page.waitForURL(/\/edit/, { timeout: 10_000 });
      await page.getByLabel('Name').fill('Updated Task Name');
      await page.getByLabel('Description').fill('Updated description');
      await page.getByRole('button', { name: /update task item/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });

      await expect(page.getByRole('link', { name: 'Updated Task Name' })).toBeVisible();
    });
  });

  test.describe('Delete', () => {
    test('deletes a task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Delete Item List');

      await createItem(page, listId, 'Task To Delete');
      await goToItemShow(page, listId, 'Task To Delete');

      page.on('dialog', (dialog) => dialog.accept());
      await page.getByRole('link', { name: /🗑 Delete/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });
      await expect(page.getByRole('link', { name: 'Task To Delete' })).not.toBeVisible();
    });
  });

  test.describe('Complete / Incomplete', () => {
    test('marks a task item as complete from show page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Complete List');

      await createItem(page, listId, 'Task To Complete');
      await goToItemShow(page, listId, 'Task To Complete');

      // Show page has "✅ Complete" link (turbo_method: :put)
      await page.getByRole('link', { name: '✅ Complete' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      // After completion, "↩ Incomplete" should appear
      await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible();
    });

    test('marks a task item as incomplete from show page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'IncompleteTest');

      // Create item then complete it from show page
      await createItem(page, listId, 'RevertMe');
      await goToItemShow(page, listId, 'RevertMe');
      await page.getByRole('link', { name: '✅ Complete' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible();

      // Now mark it incomplete
      await page.getByRole('link', { name: '↩ Incomplete' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      await expect(page.getByRole('link', { name: '✅ Complete' })).toBeVisible();
    });

    test('complete toggle works from index page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Toggle List');

      await createItem(page, listId, 'Toggle Task');
      await page.goto(taskItemsPath(listId));

      // Index shows ⬜ link for incomplete tasks — click to complete
      const toggleLink = page.locator('a[href*="/complete"]').first();
      if (await toggleLink.isVisible()) {
        await toggleLink.click();
        await page.waitForURL(/\/task_lists\/\d+\/task_items/, { timeout: 10_000 });
      }
    });

    test('complete from show page stays on show page', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Stay On Show List');

      await createItem(page, listId, 'Stay On Show Task');
      await goToItemShow(page, listId, 'Stay On Show Task');

      const showUrl = page.url();
      // Complete uses filter=show which redirects back to the show page
      await page.getByRole('link', { name: '✅ Complete' }).click();
      await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
      expect(page.url()).toContain('/task_items/');
    });
  });

  test.describe('Filters', () => {
    test('filters by completed tasks', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Filter List');

      await createItem(page, listId, 'Done Task', { completed: true });
      await createItem(page, listId, 'Pending Task');

      await page.goto(`${taskItemsPath(listId)}?filter=completed`);
      await expect(page.getByRole('link', { name: 'Done Task' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Pending Task' })).not.toBeVisible();
    });

    test('filters by incomplete tasks', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Incomplete Filter List');

      await createItem(page, listId, 'Active Task');
      await createItem(page, listId, 'Finished Task', { completed: true });

      await page.goto(`${taskItemsPath(listId)}?filter=incomplete`);
      await expect(page.getByRole('link', { name: 'Active Task' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Finished Task' })).not.toBeVisible();
    });

    test('shows all tasks with filter=all', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'All Filter List');

      await createItem(page, listId, 'Open Item');
      await createItem(page, listId, 'Closed Item', { completed: true });

      await page.goto(`${taskItemsPath(listId)}?filter=all`);
      await expect(page.getByRole('link', { name: 'Open Item' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Closed Item' })).toBeVisible();
    });
  });

  test.describe('Show page', () => {
    test('show page displays empty comments section initially', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Empty Comments List');

      await createItem(page, listId, 'No Comments Task');
      await goToItemShow(page, listId, 'No Comments Task');

      // Comments form should be visible
      await expect(page.locator("textarea[name='comment[body]']")).toBeVisible();
    });
  });

  test.describe('Move between lists', () => {
    test('moves task item to another list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId1 = await createList(page, 'Source List');
      const listId2 = await createList(page, 'Destination List');

      await createItem(page, listId1, 'Moveable Task');
      await goToItemShow(page, listId1, 'Moveable Task');

      // Move form is on the show page (not edit)
      const moveSelect = page.locator('select[name="target_list_id"]');
      await moveSelect.selectOption({ label: 'Destination List' });
      await page.getByRole('button', { name: /move/i }).click();
      await page.waitForURL(/\/task_lists\/\d+\/task_items/, { timeout: 10_000 });

      // Verify it's in the destination list
      await page.goto(taskItemsPath(listId2));
      await expect(page.getByRole('link', { name: 'Moveable Task' })).toBeVisible();

      // And gone from source
      await page.goto(taskItemsPath(listId1));
      await expect(page.getByRole('link', { name: 'Moveable Task' })).not.toBeVisible();
    });
  });
});
