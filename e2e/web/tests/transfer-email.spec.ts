import { test, expect } from '@playwright/test';
import { uniqueUser, signUp } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import { newTaskListPath, taskListPath } from './support/routes';

test.describe('Transfer Email', () => {
  test('transfer request sends email to recipient with review link', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();

    // Create recipient account
    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);
    await recipientCtx.close();

    // Owner signs up and creates a list
    await signUp(page, owner);
    await page.goto(newTaskListPath());
    await page.getByLabel('Name').fill('EmailTestList');
    await page.getByRole('button', { name: /create task list/i }).click();
    await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
    const listId = page.url().match(/\/task_lists\/(\d+)/)?.[1] ?? '';

    // Clear mailbox before transfer
    await clearMailbox();

    // Initiate transfer
    await page.goto(taskListPath(listId));
    await page.getByRole('link', { name: /transfer/i }).click();
    await page.waitForURL(/\/transfer/, { timeout: 10_000 });

    page.once('dialog', (d) => d.accept());
    await page.locator('#to_email').fill(recipient.email);
    await page.getByRole('button', { name: /send transfer/i }).click();
    await page.waitForLoadState('networkidle');

    // Verify email was sent
    const email = await waitForEmail(recipient.email, { timeout: 20_000 });
    expect(email.Subject).toContain('EmailTestList');
    expect(email.To[0].Address).toBe(recipient.email);

    // Verify email body contains the list name and a review link
    const body = await getEmailBody(email.ID);
    expect(body).toContain('EmailTestList');
    const reviewLink = extractLink(body, '/transfers/');
    expect(reviewLink).toBeTruthy();
  });

  test('transfer email review link leads to transfer details page', async ({ page, browser }) => {
    const owner = uniqueUser();
    const recipient = uniqueUser();

    // Create recipient
    const recipientCtx = await browser.newContext();
    const recipientPage = await recipientCtx.newPage();
    await signUp(recipientPage, recipient);

    // Owner creates list and initiates transfer
    await signUp(page, owner);
    await page.goto(newTaskListPath());
    await page.getByLabel('Name').fill('LinkTestList');
    await page.getByRole('button', { name: /create task list/i }).click();
    await page.waitForURL(/\/task_lists\/\d+$/, { timeout: 10_000 });
    const listId = page.url().match(/\/task_lists\/(\d+)/)?.[1] ?? '';

    await clearMailbox();

    await page.goto(taskListPath(listId));
    await page.getByRole('link', { name: /transfer/i }).click();
    await page.waitForURL(/\/transfer/, { timeout: 10_000 });
    page.once('dialog', (d) => d.accept());
    await page.locator('#to_email').fill(recipient.email);
    await page.getByRole('button', { name: /send transfer/i }).click();
    await page.waitForLoadState('networkidle');

    // Get email and follow link
    const email = await waitForEmail(recipient.email, { timeout: 20_000 });
    const body = await getEmailBody(email.ID);
    const reviewLink = extractLink(body, '/transfers/');

    // Recipient follows the link
    await recipientPage.goto(reviewLink);
    await expect(recipientPage.getByText('LinkTestList')).toBeVisible();
    await expect(recipientPage.getByRole('link', { name: /accept transfer/i })).toBeVisible();

    await recipientCtx.close();
  });
});
