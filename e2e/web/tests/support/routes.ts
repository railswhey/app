// Route path helpers — single source of truth for all URL paths.
// When routes change, update only this file.

// ── Root ─────────────────────────────────────────────────────────────────────

export function rootPath() { return '/'; }

// ── Users / Auth ─────────────────────────────────────────────────────────────

export function newUserPath() { return '/users/new'; }
export function userSessionPath() { return '/users/session'; }
export function userProfilePath() { return '/users/profile'; }
export function userPasswordPath() { return '/users/password'; }
export function userPasswordResetPath(token: string) { return `/users/${token}/password`; }
export function userTokenPath() { return '/users/token'; }

// ── Task Lists ───────────────────────────────────────────────────────────────

export function taskListsPath() { return '/task_lists'; }
export function newTaskListPath() { return '/task_lists/new'; }
export function taskListPath(id: string) { return `/task_lists/${id}`; }
export function editTaskListPath(id: string) { return `/task_lists/${id}/edit`; }

// ── Task Items (nested under task list) ──────────────────────────────────────

export function taskItemsPath(listId: string) { return `/task_lists/${listId}/task_items`; }
export function newTaskItemPath(listId: string) { return `/task_lists/${listId}/task_items/new`; }
export function taskItemPath(listId: string, id: string) { return `/task_lists/${listId}/task_items/${id}`; }
export function editTaskItemPath(listId: string, id: string) { return `/task_lists/${listId}/task_items/${id}/edit`; }

// ── Transfers ────────────────────────────────────────────────────────────────

export function newTransferPath(listId: string) { return `/task_lists/${listId}/transfer/new`; }

// ── My Tasks ─────────────────────────────────────────────────────────────────

export function myTasksPath() { return '/my_tasks'; }

// ── Search ───────────────────────────────────────────────────────────────────

export function searchPath() { return '/search'; }

// ── Notifications ────────────────────────────────────────────────────────────

export function notificationsPath() { return '/notifications'; }

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
