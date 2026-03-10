const MAILPIT_BASE = process.env.MAILPIT_URL ?? 'http://localhost:8025/api/v1';

interface MailpitMessage {
  ID: string;
  From: { Address: string };
  To: { Address: string }[];
  Subject: string;
  Snippet: string;
}

interface MailpitListResponse {
  messages: MailpitMessage[] | null;
  total: number;
}

/**
 * Delete all messages from the Mailpit inbox.
 */
export async function clearMailbox(): Promise<void> {
  const res = await fetch(`${MAILPIT_BASE}/messages`, { method: 'DELETE' });
  if (!res.ok) {
    throw new Error(`clearMailbox failed: ${res.status} ${res.statusText}`);
  }
}

/**
 * Poll the Mailpit search endpoint until an email arrives for the given
 * recipient address (or subject substring).  Throws if the timeout expires.
 *
 * @param toAddress  Recipient email address to search for.
 * @param opts.timeout  Max ms to wait (default 15 000).
 * @param opts.interval Poll interval ms (default 500).
 */
export async function waitForEmail(
  toAddress: string,
  opts: { timeout?: number; interval?: number } = {}
): Promise<MailpitMessage> {
  const { timeout = 15_000, interval = 500 } = opts;
  const deadline = Date.now() + timeout;

  while (Date.now() < deadline) {
    const url = `${MAILPIT_BASE}/search?query=${encodeURIComponent(`to:${toAddress}`)}`;
    const res = await fetch(url);
    if (res.ok) {
      const data: MailpitListResponse = await res.json();
      if (data.messages && data.messages.length > 0) {
        return data.messages[0];
      }
    }
    await new Promise((r) => setTimeout(r, interval));
  }

  throw new Error(`waitForEmail: no email for ${toAddress} after ${timeout}ms`);
}

/**
 * Fetch the HTML body of a Mailpit message.
 *
 * Mailpit stores the HTML part at part index 0 for most messages.
 * Falls back to the text part if HTML is not available.
 */
export async function getEmailBody(messageId: string): Promise<string> {
  // Try the full message endpoint first (most reliable)
  const msgRes = await fetch(`${MAILPIT_BASE}/message/${messageId}`);
  if (msgRes.ok) {
    const data = await msgRes.json();
    if (data.HTML && data.HTML.trim().length > 0) return data.HTML;
    if (data.Text && data.Text.trim().length > 0) return data.Text;
    if (data.Snippet) return data.Snippet;
  }

  // Fallback: try part endpoints
  for (const partIndex of [0, 1]) {
    const partRes = await fetch(`${MAILPIT_BASE}/message/${messageId}/part/${partIndex}`);
    if (partRes.ok) {
      const text = await partRes.text();
      if (text.trim().length > 0) return text;
    }
  }

  throw new Error(`getEmailBody: could not retrieve body for message ${messageId}`);
}

/**
 * Extract the first href from an anchor tag in an HTML email body.
 *
 * Optionally filter by a substring that must appear in the href (e.g. "/invitations/").
 */
export function extractLink(htmlBody: string, hrefContains?: string): string {
  // Match all href attributes in anchor tags
  const hrefPattern = /href="([^"]+)"/gi;
  let match: RegExpExecArray | null;

  while ((match = hrefPattern.exec(htmlBody)) !== null) {
    const href = match[1];
    if (!hrefContains || href.includes(hrefContains)) {
      return href;
    }
  }

  // Fallback: match plain URLs (for text-only emails)
  const urlPattern = /https?:\/\/[^\s<>"]+/gi;
  while ((match = urlPattern.exec(htmlBody)) !== null) {
    const url = match[0];
    if (!hrefContains || url.includes(hrefContains)) {
      return url;
    }
  }

  throw new Error(
    `extractLink: no link${hrefContains ? ` containing "${hrefContains}"` : ''} found in email body`
  );
}
