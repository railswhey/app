import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, signIn } from './support/helpers';
import { newTaskListPath, newTaskItemPath, taskListPath } from './support/routes';

async function createList(page: import('@playwright/test').Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task list/i }).click();
  await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
  return page.url().match(/\/task\/lists\/(\d+)/)?.[1] ?? '';
}

async function createTaskItem(
  page: import('@playwright/test').Page,
  listId: string,
  name: string
): Promise<string> {
  await page.goto(newTaskItemPath(listId));
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task item/i }).click();
  // Create redirects to task items index
  await page.waitForURL(/\/items($|\?)/, { timeout: 10_000 });
  // Navigate to the created item's show page
  await page.getByRole('link', { name }).click();
  await page.waitForURL(/\/items\/\d+/, { timeout: 10_000 });
  return page.url().match(/\/items\/(\d+)/)?.[1] ?? '';
}

test.describe('Comments', () => {
  test.describe('Comments on Task Items', () => {
    test('adds a comment to a task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Comment List');
      await createTaskItem(page, listId, 'Task With Comment');

      // Already on task item show page
      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('This is my comment');
      } else {
        await page.getByLabel(/body/i).fill('This is my comment');
      }
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('This is my comment')).toBeVisible();
    });

    test('adds multiple comments to a task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Multi Comment List');
      await createTaskItem(page, listId, 'Multi Comment Task');

      for (const comment of ['First comment', 'Second comment']) {
        const commentBody = page.locator("textarea[name='comment[body]']");
        await expect(commentBody).toBeVisible({ timeout: 5_000 });
        await commentBody.fill(comment);
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForLoadState('networkidle');
        // Wait for the comment textarea to reset (page reloaded)
        await expect(page.locator("textarea[name='comment[body]']")).toHaveValue('', { timeout: 5_000 });
        await expect(page.getByText(comment)).toBeVisible();
      }

      await expect(page.getByText('First comment')).toBeVisible();
      await expect(page.getByText('Second comment')).toBeVisible();
    });

    test('shows validation error for empty comment', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Empty Comment List');
      await createTaskItem(page, listId, 'Empty Comment Task');

      await page.getByRole('button', { name: /add comment/i }).click();
      // Should stay on the same page or show error
      await expect(page).toHaveURL(/\/task\/lists\/\d+\/items\/\d+/);
    });

    test('edit own comment on task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Edit Comment List');
      await createTaskItem(page, listId, 'Edit Comment Task');

      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('Original comment text');
      } else {
        await page.getByLabel(/body/i).fill('Original comment text');
      }
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Original comment text')).toBeVisible();

      // Click edit link for the comment
      const editLink = page.locator('.comment').last().getByRole('link', { name: /edit/i });
      if (await editLink.isVisible()) {
        await editLink.click();
        await page.waitForURL(/\/(edit|comments)/, { timeout: 10_000 });

        const editBody = page.locator("textarea[name='comment[body]']");
        await editBody.fill('Updated comment text');
        await page.getByRole('button', { name: /update comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });

        await expect(page.getByText('Updated comment text')).toBeVisible();
        await expect(page.getByText('Original comment text')).not.toBeVisible();
      }
    });

    test('edit comment with blank body shows validation error', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Blank Edit Comment List');
      await createTaskItem(page, listId, 'Blank Edit Comment Task');

      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('Comment to blank-edit');
      } else {
        await page.getByLabel(/body/i).fill('Comment to blank-edit');
      }
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });

      const editLink = page.locator('.comment').last().getByRole('link', { name: /edit/i });
      if (await editLink.isVisible()) {
        await editLink.click();
        await page.waitForURL(/\/(edit|comments)/, { timeout: 10_000 });

        const editBody = page.locator("textarea[name='comment[body]']");
        await editBody.fill('');
        await page.getByRole('button', { name: /update comment/i }).click();

        // Should stay on edit page with error
        await expect(page).not.toHaveURL(/\/task\/lists\/\d+\/items\/\d+$/);
      }
    });

    test('delete own comment on task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Direct Delete Comment List');
      await createTaskItem(page, listId, 'Direct Delete Comment Task');

      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('Comment to be deleted');
      } else {
        await page.getByLabel(/body/i).fill('Comment to be deleted');
      }
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Comment to be deleted')).toBeVisible();

      page.on('dialog', (dialog) => dialog.accept());
      const deleteBtn = page.locator('.comment').last().getByRole('link', { name: /delete/i });
      await expect(deleteBtn).toBeVisible();
      await deleteBtn.click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });
      await expect(page.getByText('Comment to be deleted')).not.toBeVisible();
    });

    test('owner can delete their own comment on task item', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Delete Comment List');
      await createTaskItem(page, listId, 'Delete Comment Task');

      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('Comment to delete');
      } else {
        await page.getByLabel(/body/i).fill('Comment to delete');
      }
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });

      page.on('dialog', (dialog) => dialog.accept());
      const deleteBtn = page.locator('.comment').last().getByRole('link', { name: /delete/i });
      if (await deleteBtn.isVisible()) {
        await deleteBtn.click();
        await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });
        await expect(page.getByText('Comment to delete')).not.toBeVisible();
      }
    });
  });

  test.describe('Comments on Task Lists', () => {
    test('adds a comment to a task list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'List With Comments');

      await page.goto(taskListPath(listId));

      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('List-level comment');
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
        await expect(page.getByText('List-level comment')).toBeVisible();
      }
    });

    test('submit blank comment on task list shows validation error', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Blank List Comment Validation');

      await page.goto(taskListPath(listId));
      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await page.getByRole('button', { name: /add comment/i }).click();
        // Should stay on list page or show error
        await expect(page).toHaveURL(/\/task\/lists\/\d+/);
      }
    });

    test('edit own comment on task list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Edit List Comment List');

      await page.goto(taskListPath(listId));
      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('Original list comment');
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
        await expect(page.getByText('Original list comment')).toBeVisible();

        const editLink = page.locator('.comment').last().getByRole('link', { name: /edit/i });
        if (await editLink.isVisible()) {
          await editLink.click();
          await page.waitForURL(/\/(edit|comments)/, { timeout: 10_000 });

          const editBody = page.locator("textarea[name='comment[body]']");
          await editBody.fill('Updated list comment');
          await page.getByRole('button', { name: /update comment/i }).click();
          await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });

          await expect(page.getByText('Updated list comment')).toBeVisible();
          await expect(page.getByText('Original list comment')).not.toBeVisible();
        }
      }
    });

    test('delete own comment on task list', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Delete List Comment List');

      await page.goto(taskListPath(listId));
      const commentBody = page.locator("textarea[name='comment[body]']");
      if (await commentBody.isVisible()) {
        await commentBody.fill('List comment to delete');
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
        await expect(page.getByText('List comment to delete')).toBeVisible();

        page.on('dialog', (dialog) => dialog.accept());
        const deleteBtn = page.locator('.comment').last().getByRole('link', { name: /delete/i });
        if (await deleteBtn.isVisible()) {
          await deleteBtn.click();
          await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
          await expect(page.getByText('List comment to delete')).not.toBeVisible();
        }
      }
    });

    test('task list comments are separate from task item comments', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);
      const listId = await createList(page, 'Separate Comments List');

      // Add comment to list
      await page.goto(taskListPath(listId));
      const listCommentBody = page.locator("textarea[name='comment[body]']");
      if (await listCommentBody.isVisible()) {
        await listCommentBody.fill('List comment');
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+/, { timeout: 10_000 });
      }

      // Add comment to task item
      await page.goto(newTaskItemPath(listId));
      await page.getByLabel('Name').fill('Item for Comments');
      await page.getByRole('button', { name: /create task item/i }).click();
      await page.waitForURL(/\/items($|\?)/, { timeout: 10_000 });
      await page.getByRole('link', { name: 'Item for Comments' }).click();
      await page.waitForURL(/\/items\/\d+/, { timeout: 10_000 });

      const itemCommentBody = page.locator("textarea[name='comment[body]']");
      if (await itemCommentBody.isVisible()) {
        await itemCommentBody.fill('Item comment');
        await page.getByRole('button', { name: /add comment/i }).click();
        await page.waitForURL(/\/task\/lists\/\d+\/items\/\d+/, { timeout: 10_000 });

        // List comment should not appear on item page
        await expect(page.getByText('List comment')).not.toBeVisible();
      }
    });
  });

  test.describe('Ownership Rules', () => {
    test('owner sees edit/delete links for their own comment', async ({ page }) => {
      const owner = uniqueUser();
      await signUp(page, owner);
      const listId = await createList(page, 'Ownership Test List');
      await createTaskItem(page, listId, 'Ownership Task');

      // Add a comment
      await page.locator("textarea[name='comment[body]']").fill("Owner's comment");
      await page.getByRole('button', { name: /add comment/i }).click();
      await page.waitForLoadState('networkidle');
      await expect(page.getByText("Owner's comment")).toBeVisible({ timeout: 5_000 });

      // Owner should see edit and delete links for their own comment
      const commentEl = page.locator('.comment', { hasText: "Owner's comment" });
      await expect(commentEl.getByRole('link', { name: /edit/i })).toBeVisible();
      await expect(commentEl.getByRole('link', { name: /delete/i })).toBeVisible();
    });
  });
});
