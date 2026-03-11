// Route path helpers — single source of truth for all URL paths.
// When routes change, update only this file.

// ── Root ─────────────────────────────────────────────────────────────────────

export function rootPath() { return '/'; }

// ── Users / Auth ─────────────────────────────────────────────────────────────

export function newUserPath() { return '/user/registrations/new'; }
export function userSessionPath() { return '/user/session'; }
export function userProfilePath() { return '/user/profile'; }
export function userPasswordPath() { return '/user/passwords'; }
export function userPasswordResetPath(token: string) { return `/user/passwords/${token}/edit`; }
export function userTokenPath() { return '/user/token'; }

// ── Task Lists ───────────────────────────────────────────────────────────────

export function taskListsPath() { return '/task/lists'; }
export function newTaskListPath() { return '/task/lists/new'; }
export function taskListPath(id: string) { return `/task/lists/${id}`; }
export function editTaskListPath(id: string) { return `/task/lists/${id}/edit`; }

// ── Task Items (nested under task list) ──────────────────────────────────────

export function taskItemsPath(listId: string) { return `/task/lists/${listId}/items`; }
export function newTaskItemPath(listId: string) { return `/task/lists/${listId}/items/new`; }
export function taskItemPath(listId: string, id: string) { return `/task/lists/${listId}/items/${id}`; }
export function editTaskItemPath(listId: string, id: string) { return `/task/lists/${listId}/items/${id}/edit`; }

// ── Transfers ────────────────────────────────────────────────────────────────

export function newTransferPath(listId: string) { return `/task/lists/${listId}/transfer/new`; }

// ── My Tasks ─────────────────────────────────────────────────────────────────

export function myTasksPath() { return '/my_tasks'; }

// ── Search ───────────────────────────────────────────────────────────────────

export function searchPath() { return '/search'; }

// ── Notifications ────────────────────────────────────────────────────────────

export function notificationsPath() { return '/user/notifications'; }

// ── Account ──────────────────────────────────────────────────────────────────

export function accountPath() { return '/account'; }

// ── Settings ─────────────────────────────────────────────────────────────────

export function settingsPath() { return '/settings'; }

// ── API Docs ─────────────────────────────────────────────────────────────────

export function apiDocsPath() { return '/api/docs'; }
export function apiDocsSectionPath(section: string) { return `/api/docs/${section}`; }
export function apiDocsRawPath() { return '/api/docs.md'; }

// ── Error Pages ──────────────────────────────────────────────────────────────

export function errorPagePath(code: number) { return `/${code}`; }
