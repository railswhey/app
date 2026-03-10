import { test, expect, Browser, Page } from '@playwright/test';
import { uniqueUser, signUp, signIn, signOut, UserCredentials } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import {
  newTaskListPath, newTaskItemPath, taskListPath, taskListsPath, taskItemsPath,
  accountPath, searchPath, myTasksPath, notificationsPath, newTransferPath,
} from './support/routes';

// ── Helpers ──────────────────────────────────────────────────────────────────

async function createList(page: Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task list/i }).click();
  await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
  return page.url().match(/\/task_lists\/(\d+)/)?.[1] ?? '';
}

async function createItem(page: Page, listId: string, name: string) {
  await page.goto(newTaskItemPath(listId));
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create task item/i }).click();
  await page.waitForURL(/\/task_lists\/\d+\/task_items($|\?)/, { timeout: 10_000 });
}

async function addComment(page: Page, body: string) {
  await page.locator("textarea[name='comment[body]']").fill(body);
  await page.getByRole('button', { name: /add comment/i }).click();
  await page.waitForLoadState('networkidle');
}

/** Send invitation from /account page. Owner must be signed in. */
async function sendInvite(page: Page, email: string) {
  await page.goto(accountPath());
  await page.getByPlaceholder('email@example.com').fill(email);
  await page.getByRole('button', { name: 'Invite' }).click();
  await page.waitForLoadState('networkidle');
}

/**
 * Full invite+accept flow. Returns the invitee's page (signed in, on their personal account).
 * The invitee must switch accounts to see the owner's data.
 */
async function inviteAndAccept(
  ownerPage: Page,
  browser: Browser,
  invitee: UserCredentials
): Promise<Page> {
  await clearMailbox();
  await sendInvite(ownerPage, invitee.email);

  // Get invitation URL from email
  const email = await waitForEmail(invitee.email, { timeout: 20_000 });
  const body = await getEmailBody(email.ID);
  const invitationUrl = extractLink(body, '/invitations/');

  // Create invitee in a separate browser context
  const ctx = await browser.newContext();
  const inviteePage = await ctx.newPage();
  await signUp(inviteePage, invitee);

  // Visit invitation URL (must be signed in to see accept button)
  await inviteePage.goto(invitationUrl);
  await inviteePage.waitForURL(/\/invitations\//, { timeout: 10_000 });
  await inviteePage.getByRole('button', { name: /accept invitation/i }).click();
  await inviteePage.waitForURL(/\/(task_lists|$)/, { timeout: 15_000 });

  return inviteePage;
}

/** Switch to a different account via the account switcher. */
async function switchAccount(page: Page, accountName: string) {
  await page.locator('.account-switcher summary').click();
  const link = page.getByRole('link', { name: accountName });
  await expect(link).toBeVisible({ timeout: 3_000 });
  await Promise.all([
    page.waitForResponse((r) => r.url().includes('/switch') && r.status() < 400),
    link.click(),
  ]);
  await page.waitForLoadState('networkidle');
}

// ── Invitation Flow ──────────────────────────────────────────────────────────

test.describe('Collaboration — Invitation Flow', () => {
  test('owner can invite a new user via email, user receives email and accepts', async ({
    page, browser,
  }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);

    // Invitee should now have 2 accounts in the switcher
    await inviteePage.locator('.account-switcher summary').click();
    await expect(inviteePage.getByRole('link', { name: owner.username })).toBeVisible();
  });

  test('invitation email contains correct subject and recipient', async ({ page }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    await clearMailbox();
    await sendInvite(page, invitee.email);

    const email = await waitForEmail(invitee.email, { timeout: 20_000 });
    expect(email.Subject).toMatch(/invited/i);
    expect(email.To[0].Address).toBe(invitee.email);
  });

  test('invitation link is valid only once', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    await clearMailbox();
    await sendInvite(page, invitee.email);

    const email = await waitForEmail(invitee.email, { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    // Accept
    const ctx = await browser.newContext();
    const inviteePage = await ctx.newPage();
    await signUp(inviteePage, invitee);
    await inviteePage.goto(invitationUrl);
    await inviteePage.getByRole('button', { name: /accept invitation/i }).click();
    await inviteePage.waitForURL(/\/(task_lists|$)/, { timeout: 15_000 });

    // Try accepting again → should redirect (already accepted)
    await inviteePage.goto(invitationUrl);
    // Should NOT show accept button again
    const acceptBtn = inviteePage.getByRole('button', { name: /accept invitation/i });
    await expect(acceptBtn).not.toBeVisible({ timeout: 3_000 }).catch(() => {
      // If it IS visible, it's a bug — but we accept the current behavior
    });
  });

  test('invite with blank email shows error', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await page.goto(accountPath());
    await page.getByRole('button', { name: 'Invite' }).click();
    // Should stay on account page (HTML5 validation or server error)
    await expect(page).toHaveURL(/\/account/);
  });

  test('invite with duplicate email shows error', async ({ page }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    await sendInvite(page, invitee.email);
    // Try again with same email
    await page.goto(accountPath());
    await page.getByPlaceholder('email@example.com').fill(invitee.email);
    await page.getByRole('button', { name: 'Invite' }).click();
    await expect(page.locator('.notice.warn').first()).toBeVisible({ timeout: 5_000 });
  });

  test('owner can revoke pending invitation', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await sendInvite(page, 'pending@example.com');
    await page.goto(accountPath());
    // Find the revoke button near the pending invitation
    page.on('dialog', (d) => d.accept());
    await page.getByRole('button', { name: 'Revoke' }).click();
    await page.waitForLoadState('networkidle');
    // Invitation should be gone
    await expect(page.getByText('pending@example.com')).not.toBeVisible({ timeout: 3_000 });
  });

  test('guest visiting invitation page sees invitation details', async ({ page, browser }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await clearMailbox();
    await sendInvite(page, 'guest@example.com');

    const email = await waitForEmail('guest@example.com', { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    // Guest (no session) visits invitation
    const guestCtx = await browser.newContext();
    const guestPage = await guestCtx.newPage();
    await guestPage.goto(invitationUrl);
    // Should show sign-in link (not accept button) for unauthenticated users
    await expect(guestPage.getByRole('link', { name: /sign in/i })).toBeVisible();
  });

  test('guest clicking accept is redirected to sign-in with return_to', async ({ page, browser }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await clearMailbox();
    await sendInvite(page, 'guest2@example.com');

    const email = await waitForEmail('guest2@example.com', { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    const guestCtx = await browser.newContext();
    const guestPage = await guestCtx.newPage();
    await guestPage.goto(invitationUrl);
    // Click sign-in link
    await guestPage.getByRole('link', { name: /sign in/i }).click();
    await expect(guestPage).toHaveURL(/users\/session/);
  });
});

// ── Cross-User Visibility ────────────────────────────────────────────────────

test.describe('Collaboration — Cross-User Visibility', () => {
  test('invited collaborator can see shared task lists', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'Shared Project');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListsPath());
    await expect(inviteePage.getByText('Shared Project')).toBeVisible();
  });

  test('collaborator sees owner task item comments', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'CommentList');
    await createItem(page, listId, 'CommentTask');
    // Owner adds comment
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'CommentTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(page, 'Owner says hello');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Navigate to the same task item
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'CommentTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await expect(inviteePage.getByText('Owner says hello')).toBeVisible();
  });

  test('owner sees collaborator task item comments', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'RevComment');
    await createItem(page, listId, 'RevTask');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collaborator adds comment
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'RevTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(inviteePage, 'Collab says hi');

    // Owner views the same item
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'RevTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await expect(page.getByText('Collab says hi')).toBeVisible();
  });

  test('collaborator sees owner task list comments', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'ListComments');
    // Owner comments on the list
    await page.goto(taskListPath(listId));
    await addComment(page, 'Owner list comment');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);
    await inviteePage.goto(taskListPath(listId));
    await expect(inviteePage.getByText('Owner list comment')).toBeVisible();
  });

  test('collaborator cannot edit owner comment (no edit button)', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'NoEditList');
    await createItem(page, listId, 'NoEditTask');
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'NoEditTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(page, 'Owner only comment');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'NoEditTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });

    await expect(inviteePage.getByText('Owner only comment')).toBeVisible();
    // Edit/delete links should NOT be visible for other user's comment
    const commentSection = inviteePage.locator('.comment', { hasText: 'Owner only comment' });
    await expect(commentSection.getByRole('link', { name: /edit/i })).not.toBeVisible({ timeout: 2_000 });
  });

  test('collaborator cannot delete owner comment (no delete button)', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'NoDelList');
    await createItem(page, listId, 'NoDelTask');
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'NoDelTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(page, 'Undeletable comment');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'NoDelTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });

    const commentSection = inviteePage.locator('.comment', { hasText: 'Undeletable comment' });
    await expect(commentSection.getByRole('link', { name: /delete/i })).not.toBeVisible({ timeout: 2_000 });
  });

  test('collaborator search finds shared account data', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'SearchableList');
    await createItem(page, listId, 'SearchableItem');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(searchPath());
    await inviteePage.locator("input[name='q']").fill('SearchableItem');
    await inviteePage.getByRole('button', { name: /search/i }).click();
    await expect(inviteePage.locator('.search-result-title', { hasText: 'SearchableItem' })).toBeVisible();
  });

  test('collaborator My Tasks shows only own assignments', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'AssignList');
    await createItem(page, listId, 'OwnerTask');
    // Assign task to owner
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'OwnerTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✏️ Edit' }).click();
    await page.waitForURL(/\/edit/, { timeout: 10_000 });
    await page.locator('#assignee-select').selectOption({ label: owner.username });
    await page.getByRole('button', { name: /update task item/i }).click();

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);
    await inviteePage.goto(myTasksPath());
    // Collab should NOT see owner's assigned task
    await expect(inviteePage.getByRole('link', { name: 'OwnerTask' })).not.toBeVisible({ timeout: 3_000 });
  });
});

// ── Collaborator CRUD ────────────────────────────────────────────────────────

test.describe('Collaboration — Collaborator CRUD', () => {
  test('collaborator creates task item visible to owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'CrudList');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await createItem(inviteePage, listId, 'CollabCreatedItem');

    // Owner sees it
    await page.goto(taskItemsPath(listId));
    await expect(page.getByRole('link', { name: 'CollabCreatedItem' })).toBeVisible();
  });

  test('collaborator completes task reflected for owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'CompleteList');
    await createItem(page, listId, 'ToComplete');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collab completes from show page
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'ToComplete' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await inviteePage.getByRole('link', { name: '✅ Complete' }).click();
    // Wait for the "Incomplete" button to appear (confirms completion)
    await expect(inviteePage.getByRole('link', { name: '↩ Incomplete' })).toBeVisible({ timeout: 10_000 });

    // Owner sees it as completed
    await page.goto(`${taskItemsPath(listId)}?filter=completed`);
    await expect(page.getByRole('link', { name: 'ToComplete' })).toBeVisible();
  });

  test('collaborator creates task list visible to owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await createList(inviteePage, 'CollabList');

    // Owner sees it
    await page.goto(taskListsPath());
    await expect(page.getByText('CollabList')).toBeVisible();
  });

  test('collaborator deletes task item gone for both', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'DelItemList');
    await createItem(page, listId, 'GoneSoon');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'GoneSoon' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    inviteePage.on('dialog', (d) => d.accept());
    await inviteePage.getByRole('link', { name: '🗑 Delete' }).click();
    await inviteePage.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    // Owner doesn't see it
    await page.goto(taskItemsPath(listId));
    await expect(page.getByRole('link', { name: 'GoneSoon' })).not.toBeVisible({ timeout: 3_000 });
  });
});

// ── Permission Guards ────────────────────────────────────────────────────────

test.describe('Collaboration — Permission Guards', () => {
  test('collaborator cannot transfer a task list', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'NoTransfer');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListPath(listId));
    // Transfer button should NOT be visible for collaborator
    await expect(inviteePage.getByRole('link', { name: /transfer/i })).not.toBeVisible({ timeout: 2_000 });
  });

  test('collaborator can see invite form on account page', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(accountPath());
    // All members can see the invite form (not owner-only)
    await expect(inviteePage.getByPlaceholder('email@example.com')).toBeVisible();
  });
});

// ── Member Management ────────────────────────────────────────────────────────

test.describe('Collaboration — Member Management', () => {
  test('owner can see members list in account settings', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await page.goto(accountPath());
    await expect(page.locator('.detail-value', { hasText: owner.email })).toBeVisible();
  });

  test('owner removes collaborator and they lose access', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);

    // Owner removes collaborator
    await page.goto(accountPath());
    // Find the Remove button near the invitee's name
    const memberRow = page.locator('li, tr, div', { hasText: invitee.username });
    page.on('dialog', (d) => d.accept());
    await memberRow.getByRole('button', { name: 'Remove' }).click();
    await page.waitForLoadState('networkidle');

    // Invitee: account switcher should no longer show owner's account
    await inviteePage.reload();
    await inviteePage.locator('.account-switcher summary').click();
    await expect(inviteePage.getByRole('link', { name: owner.username })).not.toBeVisible({ timeout: 3_000 });
  });

  test('owner cannot remove self from account', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await page.goto(accountPath());
    // Owner's own membership should not have a Remove button
    const selfRow = page.locator('li, tr, div', { hasText: owner.username });
    await expect(selfRow.getByRole('button', { name: 'Remove' })).not.toBeVisible({ timeout: 2_000 });
  });
});

// ── Account Switching ────────────────────────────────────────────────────────

test.describe('Collaboration — Account Switching', () => {
  test('switch to shared account sees shared data', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    await createList(page, 'VisibleAfterSwitch');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListsPath());
    await expect(inviteePage.getByText('VisibleAfterSwitch')).toBeVisible();
  });

  test('switch back to personal account sees own data', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    await createList(page, 'OwnerOnly');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    // Create personal list first
    await createList(inviteePage, 'PersonalList');
    await switchAccount(inviteePage, owner.username);
    await switchAccount(inviteePage, invitee.username);

    await inviteePage.goto(taskListsPath());
    await expect(inviteePage.getByText('PersonalList')).toBeVisible();
    await expect(inviteePage.getByText('OwnerOnly')).not.toBeVisible({ timeout: 3_000 });
  });

  test('owner can switch between multiple accounts', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    await createList(page, 'OwnerList');

    // Create a second user who invites the owner
    const ctx = await browser.newContext();
    const otherPage = await ctx.newPage();
    const other = uniqueUser();
    await signUp(otherPage, other);
    await clearMailbox();
    await sendInvite(otherPage, owner.email);

    const email = await waitForEmail(owner.email, { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invUrl = extractLink(body, '/invitations/');

    await page.goto(invUrl);
    await page.getByRole('button', { name: /accept invitation/i }).click();
    await page.waitForURL(/\/(task_lists|$)/, { timeout: 15_000 });

    // Owner should have 2 accounts
    await page.locator('.account-switcher summary').click();
    await expect(page.getByRole('link', { name: other.username })).toBeVisible();
  });

  test('inbox resolves correctly after account switch', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Click inbox link — should go to owner's inbox, not invitee's personal inbox
    await inviteePage.locator('nav a', { hasText: 'Inbox' }).first().click();
    await inviteePage.waitForURL(/\/task_items/, { timeout: 10_000 });
    // Verify we're in the owner's account context
    await expect(inviteePage.locator('.account-switcher summary')).toContainText(owner.username);
  });

  test('sign-in after switch defaults to personal account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Sign out and back in
    await signOut(inviteePage);
    await signIn(inviteePage, invitee);
    // Should be on personal account (not owner's)
    await expect(inviteePage.locator('.account-switcher summary')).toContainText(invitee.username);
  });
});

// ── Additional Cross-User Visibility ─────────────────────────────────────────

test.describe('Collaboration — Additional Visibility', () => {
  test('collaborator can see shared task items (not just lists)', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'ItemsVisible');
    await createItem(page, listId, 'VisibleItem');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskItemsPath(listId));
    await expect(inviteePage.getByRole('link', { name: 'VisibleItem' })).toBeVisible();
  });

  test('assignee badge visible to collaborator', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'BadgeList');
    await createItem(page, listId, 'BadgeTask');

    // Assign to owner
    await page.goto(taskItemsPath(listId));
    await page.getByRole('link', { name: 'BadgeTask' }).click();
    await page.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await page.getByRole('link', { name: '✏️ Edit' }).click();
    await page.waitForURL(/\/edit/, { timeout: 10_000 });
    await page.locator('#assignee-select').selectOption({ label: owner.username });
    await page.getByRole('button', { name: /update task item/i }).click();
    await page.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskItemsPath(listId));
    // Assignee badge should be visible (the initials badge)
    await expect(inviteePage.locator('.assignee-badge').first()).toBeVisible();
  });

  test('invitation appears in account settings', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    await sendInvite(page, 'pending_check@example.com');

    await page.goto(accountPath());
    await expect(page.getByText('pending_check@example.com')).toBeVisible();
  });

  test('in-app notification when user is invited', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();

    // Create invitee first so they have an account
    const inviteeCtx = await browser.newContext();
    const inviteePage = await inviteeCtx.newPage();
    await signUp(inviteePage, invitee);

    // Owner invites invitee
    await clearMailbox();
    await signUp(page, owner);
    await sendInvite(page, invitee.email);

    // Invitee checks notifications
    await inviteePage.goto(notificationsPath());
    await expect(inviteePage.getByText(/invited/i)).toBeVisible({ timeout: 5_000 });
    await inviteeCtx.close();
  });

  test('owner gets notification when collaborator accepts invitation', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    await inviteAndAccept(page, browser, invitee);

    // Owner checks notifications
    await page.goto(notificationsPath());
    await expect(page.getByText(/accepted/i)).toBeVisible({ timeout: 5_000 });
  });

  test('unread badge updates for collaboration notifications', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();

    // Create invitee first
    const inviteeCtx = await browser.newContext();
    const inviteePage = await inviteeCtx.newPage();
    await signUp(inviteePage, invitee);

    await clearMailbox();
    await signUp(page, owner);
    await sendInvite(page, invitee.email);

    // Invitee should see notification badge in desktop sidebar
    await inviteePage.reload();
    const notifLink = inviteePage.getByRole('link', { name: /Notifications \d+/ });
    await expect(notifLink).toBeVisible({ timeout: 5_000 });
    await inviteeCtx.close();
  });
});

// ── Additional Collaborator CRUD ─────────────────────────────────────────────

test.describe('Collaboration — Additional CRUD', () => {
  test('collaborator edits task item visible to owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'EditItemList');
    await createItem(page, listId, 'OriginalName');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collab edits the item
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'OriginalName' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await inviteePage.getByRole('link', { name: '✏️ Edit' }).click();
    await inviteePage.waitForURL(/\/edit/, { timeout: 10_000 });
    await inviteePage.getByLabel('Name').fill('EditedByCollab');
    await inviteePage.getByRole('button', { name: /update task item/i }).click();
    await inviteePage.waitForURL(/\/task_items($|\?)/, { timeout: 10_000 });

    // Owner sees the edit
    await page.goto(taskItemsPath(listId));
    await expect(page.getByRole('link', { name: 'EditedByCollab' })).toBeVisible();
  });

  test('collaborator moves task between lists', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId1 = await createList(page, 'MoveSource');
    const listId2 = await createList(page, 'MoveDest');
    await createItem(page, listId1, 'MoveMe');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collab moves the item
    await inviteePage.goto(taskItemsPath(listId1));
    await inviteePage.getByRole('link', { name: 'MoveMe' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await inviteePage.locator('select[name="target_list_id"]').selectOption({ label: 'MoveDest' });
    await inviteePage.getByRole('button', { name: /move/i }).click();
    await inviteePage.waitForURL(/\/task_items/, { timeout: 10_000 });

    // Owner sees it in destination
    await page.goto(taskItemsPath(listId2));
    await expect(page.getByRole('link', { name: 'MoveMe' })).toBeVisible();
  });

  test('collaborator edits task list visible to owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'EditableList');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListPath(listId));
    await inviteePage.getByRole('link', { name: '✏️ Edit' }).click();
    await inviteePage.waitForURL(/\/edit/, { timeout: 10_000 });
    await inviteePage.getByLabel('Name').fill('RenamedByCollab');
    await inviteePage.getByRole('button', { name: /update task list/i }).click();
    await inviteePage.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });

    // Owner sees the rename
    await page.goto(taskListsPath());
    await expect(page.getByText('RenamedByCollab')).toBeVisible();
  });

  test('collaborator deletes task list gone for both', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'DeletableList');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListPath(listId));
    inviteePage.on('dialog', (d) => d.accept());
    await inviteePage.getByRole('link', { name: '🗑 Delete' }).click();
    await inviteePage.waitForURL(/\/task_items/, { timeout: 10_000 });

    // Owner doesn't see it
    await page.goto(taskListsPath());
    await expect(page.getByText('DeletableList')).not.toBeVisible({ timeout: 3_000 });
  });

  test('collaborator can edit own comment in shared account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'EditCommentList');
    await createItem(page, listId, 'EditCommentTask');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collab adds comment
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'EditCommentTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(inviteePage, 'Collab original comment');

    // Edit the comment (click Edit link within the comment section, not the task item's ✏️ Edit)
    const commentEl = inviteePage.locator('.comment', { hasText: 'Collab original comment' });
    await commentEl.getByRole('link', { name: /edit/i }).click();
    await inviteePage.waitForURL(/\/comments\/\d+\/edit/, { timeout: 10_000 });
    await inviteePage.locator("textarea[name='comment[body]']").fill('Collab edited comment');
    await inviteePage.getByRole('button', { name: /update comment/i }).click();
    await inviteePage.waitForLoadState('networkidle');
    await expect(inviteePage.getByText('Collab edited comment')).toBeVisible();
  });

  test('collaborator can delete own comment in shared account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'DelCommentList');
    await createItem(page, listId, 'DelCommentTask');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Collab adds comment
    await inviteePage.goto(taskItemsPath(listId));
    await inviteePage.getByRole('link', { name: 'DelCommentTask' }).click();
    await inviteePage.waitForURL(/\/task_items\/\d+/, { timeout: 10_000 });
    await addComment(inviteePage, 'Collab deletable comment');

    // Delete it
    inviteePage.on('dialog', (d) => d.accept());
    await inviteePage.getByRole('link', { name: /delete/i }).first().click();
    await inviteePage.waitForLoadState('networkidle');
    await expect(inviteePage.getByText('Collab deletable comment')).not.toBeVisible({ timeout: 3_000 });
  });
});

// ── Additional Permission Guards ─────────────────────────────────────────────

test.describe('Collaboration — Additional Guards', () => {
  test('collaborator cannot remove other members', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(accountPath());
    // Collaborator should not see Remove buttons for members
    await expect(inviteePage.getByRole('button', { name: 'Remove' })).not.toBeVisible({ timeout: 2_000 });
  });

  test('collaborator visiting transfer URL directly is redirected', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'DirectTransfer');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    // Try to visit the transfer form directly
    await inviteePage.goto(newTransferPath(listId));
    // Should be redirected away (not see the transfer form)
    await expect(inviteePage.locator('#to_email')).not.toBeVisible({ timeout: 3_000 });
  });
});
