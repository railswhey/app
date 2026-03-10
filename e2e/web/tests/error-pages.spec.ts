import { test, expect } from '@playwright/test';
import { uniqueUser, signUp } from './support/helpers';
import { errorPagePath } from './support/routes';

test.describe('Error Pages', () => {
  test.describe('404 Not Found', () => {
    test('unauthenticated user sees 404 page with sign-in link', async ({ page }) => {
      await page.goto(errorPagePath(404));
      await expect(page.getByText('404')).toBeVisible();
      await expect(page.getByText('Page not found')).toBeVisible();
      await expect(page.getByRole('link', { name: /Go to Sign In/i })).toBeVisible();
    });

    test('authenticated user sees back-to-lists link on 404', async ({ page }) => {
      const user = uniqueUser();
      await signUp(page, user);

      await page.goto(errorPagePath(404));
      await expect(page.getByText('Page not found')).toBeVisible();
      await expect(page.getByRole('link', { name: /back to my lists/i })).toBeVisible();
    });
  });

  test.describe('422 Unprocessable Entity', () => {
    test('shows 422 page', async ({ page }) => {
      await page.goto(errorPagePath(422));
      await expect(page.getByText('422')).toBeVisible();
      await expect(page.getByText('Request not accepted')).toBeVisible();
    });

    test('unauthenticated user sees start-over link on 422', async ({ page }) => {
      await page.goto(errorPagePath(422));
      await expect(page.getByRole('link', { name: /start over/i })).toBeVisible();
    });
  });

  test.describe('500 Internal Server Error', () => {
    test('shows 500 page', async ({ page }) => {
      await page.goto(errorPagePath(500));
      await expect(page.getByText('500')).toBeVisible();
      await expect(page.getByText('Something went wrong')).toBeVisible();
    });

    test('shows go-home link on 500', async ({ page }) => {
      await page.goto(errorPagePath(500));
      await expect(page.getByRole('link', { name: /go to home/i })).toBeVisible();
    });
  });
});
