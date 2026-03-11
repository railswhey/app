import { test, expect } from '@playwright/test';
import { uniqueUser, signUp, signIn } from './support/helpers';
import { clearMailbox, waitForEmail, getEmailBody, extractLink } from './support/mailpit';
import { accountPath, taskListsPath } from './support/routes';

/**
 * Helper: owner invites collaborator, collaborator accepts, switches to owner's account.
 * Returns the collaborator page with the session on the owner's account.
 */
async function setupCollaborator(
  ownerPage: import('@playwright/test').Page,
  browser: import('@playwright/test').Browser,
  owner: ReturnType<typeof uniqueUser>,
  collaborator: ReturnType<typeof uniqueUser>
) {
  // Create collaborator account
  const collabCtx = await browser.newContext();
  const collabPage = await collabCtx.newPage();
  await signUp(collabPage, collaborator);

  // Owner invites collaborator
  await clearMailbox();
  await ownerPage.goto(accountPath());
  await ownerPage.getByPlaceholder('email@example.com').fill(collaborator.email);
  await ownerPage.getByRole('button', { name: 'Invite' }).click();
  await ownerPage.waitForLoadState('networkidle');

  // Collaborator accepts invitation
  const email = await waitForEmail(collaborator.email, { timeout: 20_000 });
  const body = await getEmailBody(email.ID);
  const invitationUrl = extractLink(body, '/invitations/');
  await collabPage.goto(invitationUrl);
  await collabPage.getByRole('button', { name: /accept invitation/i }).click();
  await collabPage.waitForURL(/\/(task\/lists|$)/, { timeout: 15_000 });

  // Collaborator switches to owner's account
  await collabPage.locator('.account-switcher summary').click();
  const ownerLink = collabPage.getByRole('link', { name: owner.username });
  await expect(ownerLink).toBeVisible({ timeout: 3_000 });
  await Promise.all([
    collabPage.waitForResponse((r) => r.url().includes('/switch') && r.status() < 400),
    ownerLink.click(),
  ]);
  await collabPage.waitForLoadState('networkidle');

  return { collabPage, collabCtx };
}

test.describe('Stale Session Recovery', () => {
  test('user recovers to own account after being removed from shared account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const collaborator = uniqueUser();
    await signUp(page, owner);

    const { collabPage, collabCtx } = await setupCollaborator(page, browser, owner, collaborator);

    // Verify collaborator is on owner's account
    await expect(collabPage.locator('.account-switcher summary')).toContainText(owner.username);

    // Owner removes collaborator
    await page.goto(accountPath());
    const removeButton = page.locator(`form[action*="memberships/"] button, a[data-turbo-method="delete"]`)
      .filter({ hasText: /remove/i })
      .first();
    if (await removeButton.isVisible()) {
      page.once('dialog', (d) => d.accept());
      await removeButton.click();
      await page.waitForLoadState('networkidle');
    }

    // Collaborator reloads — should recover to their own account
    await collabPage.goto(taskListsPath());
    await expect(collabPage).not.toHaveURL(/users\/session/);
    await expect(collabPage.locator('.account-switcher summary')).toContainText(collaborator.username);

    await collabCtx.close();
  });

  test('user can access account page after being removed from shared account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const collaborator = uniqueUser();
    await signUp(page, owner);

    const { collabPage, collabCtx } = await setupCollaborator(page, browser, owner, collaborator);

    // Owner removes collaborator
    await page.goto(accountPath());
    const removeButton = page.locator(`form[action*="memberships/"] button, a[data-turbo-method="delete"]`)
      .filter({ hasText: /remove/i })
      .first();
    if (await removeButton.isVisible()) {
      page.once('dialog', (d) => d.accept());
      await removeButton.click();
      await page.waitForLoadState('networkidle');
    }

    // Collaborator visits account page — should not crash
    await collabPage.goto(accountPath());
    await expect(collabPage).not.toHaveURL(/users\/session/);
    // Should see their own account name
    await expect(collabPage.locator('body')).toBeVisible();

    await collabCtx.close();
  });

  test('user inbox is intact after being removed from shared account', async ({ page, browser }) => {
    const owner = uniqueUser();
    const collaborator = uniqueUser();
    await signUp(page, owner);

    const { collabPage, collabCtx } = await setupCollaborator(page, browser, owner, collaborator);

    // Owner removes collaborator
    await page.goto(accountPath());
    const removeButton = page.locator(`form[action*="memberships/"] button, a[data-turbo-method="delete"]`)
      .filter({ hasText: /remove/i })
      .first();
    if (await removeButton.isVisible()) {
      page.once('dialog', (d) => d.accept());
      await removeButton.click();
      await page.waitForLoadState('networkidle');
    }

    // Collaborator navigates — inbox should still exist
    await collabPage.goto(taskListsPath());
    await expect(collabPage.getByRole('link', { name: 'Inbox', exact: true })).toBeVisible();

    await collabCtx.close();
  });
});
