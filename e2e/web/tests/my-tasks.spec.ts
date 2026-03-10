import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, openNav } from './support/helpers';
import { newTaskListPath, newTaskItemPath, taskItemsPath } from './support/routes';

async function createList(page: import('@playwright/test').Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task list/i }).click();
  await page.waitForURL(/\/task_lists\/\d+/, { timeout: 10_000 });
  return page.url().match(/\/task_lists\/(\d+)/)?.[1] ?? '';
}

/** Create a task item assigned to current user. Returns on the task items index. */
async function createAssignedItem(
  page: import('@playwright/test').Page,
  listId: string,
  name: string
) {
  await page.goto(newTaskItemPath(listId));
  await page.getByLabel('Name').fill(name);

  const assigneeSelect = page.locator('#assignee-select');
  if (await assigneeSelect.isVisible()) {
    const options = await assigneeSelect.locator('option').all();
    for (const option of options) {
      const text = await option.textContent();
      if (text && text.trim() && text !== '' && !text.match(/^(—.*—|-+)$/)) {
        await assigneeSelect.selectOption({ label: text.trim() });
        break;
      }
    }
  }

  await page.getByRole('button', { name: /create task item/i }).click();
  await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });
}

test.describe('My Tasks', () => {
  test('can navigate to My Tasks via sidebar', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page).not.toHaveURL(/users\/session/);
  });

  test('shows tasks assigned to current user', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'Assigned Tasks List');

    await createAssignedItem(page, listId, 'Self Assigned Task');

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('Self Assigned Task')).toBeVisible();
  });

  test('My Tasks filters: incomplete tasks visible by default', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'My Tasks Filter List');

    await createAssignedItem(page, listId, 'My Incomplete Task');

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('My Incomplete Task')).toBeVisible();
  });

  test('My Tasks filters: completed tasks filterable', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'My Complete Filter List');

    // Create task assigned to self (incomplete)
    await createAssignedItem(page, listId, 'My Completed Task');

    // Navigate to the item and mark it complete
    await page.getByRole('link', { name: 'My Completed Task' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✅ Complete' }).click();
    await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible({ timeout: 10_000 });

    // Navigate to My Tasks with completed filter
    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });

    const currentUrl = page.url();
    const filterUrl = currentUrl.includes('?')
      ? `${currentUrl}&filter=completed`
      : `${currentUrl}?filter=completed`;
    await page.goto(filterUrl);
    await expect(page.getByText('My Completed Task')).toBeVisible();
  });

  test('unassigned tasks do not appear in My Tasks', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'NoAssign List');

    // Create task without setting assignee
    await page.goto(newTaskItemPath(listId));
    await page.getByLabel('Name').fill('NoAssignItem');
    await page.getByRole('button', { name: /create task item/i }).click();
    await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('NoAssignItem')).not.toBeVisible();
  });

  test('empty state when no tasks assigned', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page).not.toHaveURL(/users\/session/);
    await expect(page.locator('body')).toBeVisible();
  });

  test('assign self to task and it appears in My Tasks', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'Assign Via Edit List');

    // Create task without assignee
    await page.goto(newTaskItemPath(listId));
    await page.getByLabel('Name').fill('Assign Via Edit Task');
    await page.getByRole('button', { name: /create task item/i }).click();
    await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    // Navigate to show page then edit
    await page.getByRole('link', { name: 'Assign Via Edit Task' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✏️ Edit' }).click();
    await page.waitForURL(/\/task_items\/\d+\/edit/, { timeout: 10_000 });

    const assigneeSelect = page.locator('#assignee-select');
    if (await assigneeSelect.isVisible()) {
      const options = await assigneeSelect.locator('option').all();
      for (const option of options) {
        const text = await option.textContent();
        if (text && text.trim() && !text.match(/^(—.*—|-+)$/) && text.trim() !== '') {
          await assigneeSelect.selectOption({ label: text.trim() });
          break;
        }
      }
    }

    await page.getByRole('button', { name: /update task item/i }).click();
    await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('Assign Via Edit Task')).toBeVisible();
  });

  test('unassign task and it disappears from My Tasks', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'UnassignList');

    // Create task assigned to self
    await createAssignedItem(page, listId, 'Task To Unassign');

    // Verify it appears in My Tasks
    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('Task To Unassign')).toBeVisible();

    // Now edit to remove the assignee
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: /Task To Unassign/ }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });

    await page.getByRole('link', { name: '✏️ Edit' }).click();
    await page.waitForURL(/\/task_items\/\d+\/edit/, { timeout: 10_000 });

    const editAssigneeSelect = page.locator('#assignee-select');
    if (await editAssigneeSelect.isVisible()) {
      await editAssigneeSelect.selectOption('');
    }

    await page.getByRole('button', { name: /update task item/i }).click();
    await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });
    await expect(page.getByText('Task To Unassign')).not.toBeVisible();
  });

  test('my tasks filter by completed', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'My Tasks Complete Filter List');

    // Create a task assigned to self, then mark complete
    await createAssignedItem(page, listId, 'My Completed Assigned Task');
    await page.getByRole('link', { name: 'My Completed Assigned Task' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✅ Complete' }).click();
    await expect(page.getByRole('link', { name: '↩ Incomplete' })).toBeVisible({ timeout: 10_000 });

    // Navigate to My Tasks completed filter
    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });

    const completedFilter = page.locator('.filter-tabs').getByRole('link', { name: /completed/i });
    if (await completedFilter.isVisible()) {
      await completedFilter.click();
      await page.waitForURL(/filter=completed/, { timeout: 10_000 });
    } else {
      const currentUrl = page.url();
      const filterUrl = currentUrl.includes('?') ? `${currentUrl}&filter=completed` : `${currentUrl}?filter=completed`;
      await page.goto(filterUrl);
    }

    await expect(page.getByText('My Completed Assigned Task')).toBeVisible();
  });

  test('my tasks filter by incomplete', async ({ page }) => {
    const user = uniqueUser();
    await signUp(page, user);
    const listId = await createList(page, 'My Tasks Incomplete Filter List');

    // Create an incomplete task assigned to self
    await createAssignedItem(page, listId, 'My Incomplete Assigned Task');

    // Navigate to My Tasks and click incomplete filter
    await openNav(page);
    await page.getByRole('link', { name: /👤.*my tasks/i }).click();
    await page.waitForURL(/\/my.tasks|\/task_items.*assigned/, { timeout: 10_000 });

    const incompleteFilter = page.locator('.filter-tabs').getByRole('link', { name: /incomplete/i });
    if (await incompleteFilter.isVisible()) {
      await incompleteFilter.click();
      await page.waitForURL(/filter=incomplete/, { timeout: 10_000 });
    } else {
      const currentUrl = page.url();
      const filterUrl = currentUrl.includes('?') ? `${currentUrl}&filter=incomplete` : `${currentUrl}?filter=incomplete`;
      await page.goto(filterUrl);
    }

    await expect(page.getByText('My Incomplete Assigned Task')).toBeVisible();
  });
});
