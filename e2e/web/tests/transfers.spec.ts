import { test, expect, Browser, Page } from '@playwright/test';
import { uniqueUser, signUp, signIn, signOut, UserCredentials } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import {
  newTaskListPath, taskListPath, taskListsPath, taskItemsPath, notificationsPath,
  accountPath,
} from './support/routes';

// ── Helpers ──────────────────────────────────────────────────────────────────

async function createList(page: Page, name: string): Promise<string> {
  await page.goto(newTaskListPath());
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: /create list/i }).click();
  await page.waitForURL(/\/task\/lists\/\d+$/, { timeout: 10_000 });
  return page.url().match(/\/task\/lists\/(\d+)/)?.[1] ?? '';
}

async function sendInvite(page: Page, email: string) {
  await page.goto(accountPath());
  await page.getByPlaceholder('email@example.com').fill(email);
  await page.getByRole('button', { name: 'Invite' }).click();
  await page.waitForLoadState('networkidle');
}

async function inviteAndAccept(
  ownerPage: Page, browser: Browser, invitee: UserCredentials
): Promise<Page> {
  await clearMailbox();
  await sendInvite(ownerPage, invitee.email);
  const email = await waitForEmail(invitee.email, { timeout: 20_000 });
  const body = await getEmailBody(email.ID);
  const invitationUrl = extractLink(body, '/invitations/');

  const ctx = await browser.newContext();
  const inviteePage = await ctx.newPage();
  await signUp(inviteePage, invitee);
  await inviteePage.goto(invitationUrl);
  await inviteePage.getByRole('button', { name: /accept invitation/i }).click();
  await inviteePage.waitForURL(/\/(task\/lists|$)/, { timeout: 15_000 });
  return inviteePage;
}

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

/** Initiate a transfer of list to recipient (handles turbo_confirm dialog). */
async function initiateTransfer(page: Page, listId: string, recipientEmail: string) {
  await page.goto(taskListPath(listId));
  await page.getByRole('link', { name: /transfer/i }).click();
  await page.waitForURL(/\/transfer/, { timeout: 10_000 });

  page.once('dialog', (d) => d.accept());
  await page.locator('#to_email').fill(recipientEmail);
  await page.getByRole('button', { name: /send transfer/i }).click();
  await page.waitForLoadState('networkidle');
}

// ── Transfer Tests ───────────────────────────────────────────────────────────

test.describe('Transfers', () => {
  test('owner can transfer a task list to a collaborator', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'Transferable');

    const recipientPage = await inviteAndAccept(page, browser, recipient);

    await initiateTransfer(page, listId, recipient.email);

    // Should redirect with a flash confirming transfer was sent
    await expect(page.locator('.notice, .alert')).toBeVisible({ timeout: 5_000 });
  });

  test('transfer to non-existent user shows error', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'NoRecipient');

    await page.goto(taskListPath(listId));
    await page.getByRole('link', { name: /transfer/i }).click();
    await page.waitForURL(/\/transfer/, { timeout: 10_000 });

    page.once('dialog', (d) => d.accept());
    await page.locator('#to_email').fill('nobody@nonexistent.com');
    await page.getByRole('button', { name: /send transfer/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('.notice.error, .notice.alert, [class*="error"]').first()).toBeVisible({ timeout: 5_000 });
  });

  test('collaborator cannot see transfer button on list show page', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'GuardedList');

    const inviteePage = await inviteAndAccept(page, browser, invitee);
    await switchAccount(inviteePage, owner.username);

    await inviteePage.goto(taskListPath(listId));
    await expect(inviteePage.getByRole('link', { name: /transfer/i })).not.toBeVisible({ timeout: 2_000 });
  });

  test('transfer to user without account shows error', async ({ page }) => {
    const owner = uniqueUser();
    await signUp(page, owner);
    const listId = await createList(page, 'NoAccountTransfer');

    await page.goto(taskListPath(listId));
    await page.getByRole('link', { name: /transfer/i }).click();
    await page.waitForURL(/\/transfer/, { timeout: 10_000 });

    page.once('dialog', (d) => d.accept());
    await page.locator('#to_email').fill('no_account_whatsoever@nonexistent.com');
    await page.getByRole('button', { name: /send transfer/i }).click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('.notice.error, .notice.alert, [class*="error"]').first()).toBeVisible({ timeout: 5_000 });
  });

  test('recipient can accept transfer and list moves to their account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();

    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);

    await signUp(page, owner);
    const listId = await createList(page, 'TransferAccept');
    await initiateTransfer(page, listId, recipient.email);

    // Recipient checks notifications for transfer link
    await recipientPage.goto(notificationsPath());
    const transferLink = recipientPage.locator('a[href*="/transfers/"]').first();
    await expect(transferLink).toBeVisible({ timeout: 10_000 });
    await transferLink.click();
    await recipientPage.waitForURL(/\/transfers\//, { timeout: 10_000 });

    // Accept
    recipientPage.once('dialog', (d) => d.accept());
    await recipientPage.getByRole('link', { name: /accept transfer/i }).click();
    await recipientPage.waitForLoadState('networkidle');

    // Verify list is now in recipient's account
    await recipientPage.goto(taskListsPath());
    await expect(recipientPage.getByText('TransferAccept')).toBeVisible();
    await recipientCtx.close();
  });

  test('recipient can reject transfer and list stays with owner', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();

    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);

    await signUp(page, owner);
    const listId = await createList(page, 'TransferReject');
    await initiateTransfer(page, listId, recipient.email);

    // Recipient declines
    await recipientPage.goto(notificationsPath());
    const transferLink = recipientPage.locator('a[href*="/transfers/"]').first();
    await expect(transferLink).toBeVisible({ timeout: 10_000 });
    await transferLink.click();
    await recipientPage.waitForURL(/\/transfers\//, { timeout: 10_000 });

    recipientPage.once('dialog', (d) => d.accept());
    await recipientPage.getByRole('link', { name: /decline/i }).click();
    await recipientPage.waitForLoadState('networkidle');

    // List still with owner
    await page.goto(taskListsPath());
    await expect(page.getByText('TransferReject').first()).toBeVisible();
    await recipientCtx.close();
  });

  test('recipient can view transfer page after signing in', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();

    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);

    await signUp(page, owner);
    const listId = await createList(page, 'ViewTransfer');
    await initiateTransfer(page, listId, recipient.email);

    // Recipient visits notifications to find transfer
    await recipientPage.goto(notificationsPath());
    const transferLink = recipientPage.locator('a[href*="/transfers/"]').first();
    await expect(transferLink).toBeVisible({ timeout: 10_000 });
    await transferLink.click();
    await recipientPage.waitForURL(/\/transfers\//, { timeout: 10_000 });

    // Should see transfer details with list name and accept/decline buttons
    await expect(recipientPage.getByText('ViewTransfer')).toBeVisible();
    await expect(recipientPage.getByRole('link', { name: /accept transfer/i })).toBeVisible();
    await expect(recipientPage.getByRole('link', { name: /decline/i })).toBeVisible();
    await recipientCtx.close();
  });
});
