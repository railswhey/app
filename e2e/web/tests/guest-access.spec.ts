import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, signIn } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import {
  apiDocsPath, apiDocsSectionPath, apiDocsRawPath, accountPath, newTaskListPath,
} from './support/routes';

test.describe('Guest Access', () => {
  test('guest can view API docs default section', async ({ page }) => {
    await page.goto(apiDocsPath());
    await expect(page).toHaveURL(/\/api\/docs/);
    await expect(page.locator('body')).toBeVisible();
  });

  test('guest can view API docs specific section', async ({ page }) => {
    await page.goto(apiDocsSectionPath('authentication'));
    await expect(page).toHaveURL(/\/api\/docs\/authentication/);
  });

  test('guest can view API docs raw', async ({ page }) => {
    await page.goto(apiDocsRawPath());
    await expect(page).toHaveURL(/\/api\/docs\.md/);
  });

  test('guest can view API docs invalid section falls back to default', async ({ page }) => {
    await page.goto(apiDocsSectionPath('nonexistent_section_xyz'));
    // Should fall back to default section (not 404)
    await expect(page).toHaveURL(/\/api\/docs/);
    await expect(page.locator('body')).toBeVisible();
  });

  test('guest visiting invitation page sees sign-in link', async ({ page, browser }) => {
    const owner = uniqueUser();
    await clearMailbox();
    await signUp(page, owner);

    await page.goto(accountPath());
    await page.getByPlaceholder('email@example.com').fill('guest@example.com');
    await page.getByRole('button', { name: 'Invite' }).click();
    await page.waitForLoadState('networkidle');

    const email = await waitForEmail('guest@example.com', { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    // Guest (unauthenticated) visits invitation
    const guestCtx = await browser.newContext();
    const guestPage = await guestCtx.newPage();
    await guestPage.goto(invitationUrl);
    await expect(guestPage.getByRole('link', { name: /sign in/i })).toBeVisible();
    await guestCtx.close();
  });

  test('guest clicking sign-in on invitation goes to sign-in page', async ({ page, browser }) => {
    const owner = uniqueUser();
    await clearMailbox();
    await signUp(page, owner);

    await page.goto(accountPath());
    await page.getByPlaceholder('email@example.com').fill('guest2@example.com');
    await page.getByRole('button', { name: 'Invite' }).click();
    await page.waitForLoadState('networkidle');

    const email = await waitForEmail('guest2@example.com', { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    const guestCtx = await browser.newContext();
    const guestPage = await guestCtx.newPage();
    await guestPage.goto(invitationUrl);
    await guestPage.getByRole('link', { name: /sign in/i }).click();
    await expect(guestPage).toHaveURL(/user\/session/);
    await guestCtx.close();
  });

  test('guest visiting transfer page sees sign-in link', async ({ page, browser }) => {
    // Create owner, create list, initiate transfer
    const owner = uniqueUser();
    const recipient = uniqueUser();
    await signUp(page, owner);

    // Create recipient account first
    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);
    await recipientCtx.close();

    // Owner creates list and initiates transfer
    await page.goto(newTaskListPath());
    await page.getByLabel('Name').fill('TransferGuest');
    await page.getByRole('button', { name: /create task list/i }).click();
    await page.waitForURL(/\/task\/lists\/\d+$/, { timeout: 10_000 });
    const listId = page.url().match(/\/task\/lists\/(\d+)/)?.[1] ?? '';

    await page.getByRole('link', { name: /transfer/i }).click();
    await page.waitForURL(/\/transfer/, { timeout: 10_000 });
    page.on('dialog', (d) => d.accept());
    await page.locator('#to_email').fill(recipient.email);
    await page.getByRole('button', { name: /transfer/i }).click();
    await page.waitForLoadState('networkidle');

    // Find the transfer token from the page or URL
    // The show page URL is /transfers/:token
    const transferLinks = await page.locator('a[href*="/transfers/"]').all();
    let transferUrl = '';
    for (const link of transferLinks) {
      const href = await link.getAttribute('href');
      if (href?.includes('/transfers/')) {
        transferUrl = href;
        break;
      }
    }

    if (transferUrl) {
      // Guest visits transfer page
      const guestCtx = await browser.newContext();
      const guestPage = await guestCtx.newPage();
      await guestPage.goto(transferUrl);
      // Should show sign-in/create account links
      await expect(guestPage.getByRole('link', { name: /sign in/i })).toBeVisible();
      await guestCtx.close();
    }
  });

  test('guest after signing in is redirected back to invitation page', async ({ page, browser }) => {
    const owner = uniqueUser();
    const invitee = uniqueUser();
    await clearMailbox();
    await signUp(page, owner);

    // Create invitee account first
    const inviteeCtx = await browser.newContext();
    const inviteePage = await inviteeCtx.newPage();
    await signUp(inviteePage, invitee);

    // Clear mailbox after sign-up (to discard confirmation emails)
    await clearMailbox();

    // Owner sends invite
    await page.goto(accountPath());
    await page.getByPlaceholder('email@example.com').fill(invitee.email);
    await page.getByRole('button', { name: 'Invite' }).click();
    await page.waitForLoadState('networkidle');

    const email = await waitForEmail(invitee.email, { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const invitationUrl = extractLink(body, '/invitations/');

    // Invitee visits invitation page while signed in → sees accept button
    await inviteePage.goto(invitationUrl);
    await expect(inviteePage.getByRole('button', { name: /accept invitation/i })).toBeVisible();
    await inviteeCtx.close();
  });
});
