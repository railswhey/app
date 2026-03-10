<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/00-INSTALLATION.md">Installation</a> | <strong>Features &amp; Screenshots</strong> | <a href="/docs/02-TESTING.md">Testing</a> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a>
</small>
</p>

# App Features <!-- omit in toc -->

**Table of contents:** <!-- omit in toc -->

- [Task Management](#task-management)
- [Collaboration](#collaboration)
- [Auth \& Settings](#auth--settings)
- [API Documentation](#api-documentation)
- [Screenshots](#screenshots)
  - [Sign in](#sign-in)
  - [Sign up](#sign-up)
  - [Forgot password](#forgot-password)
  - [Task Lists](#task-lists)
  - [Task Items](#task-items)
  - [My Tasks](#my-tasks)
  - [Search](#search)
  - [Notifications](#notifications)
  - [Settings](#settings)
  - [API Docs](#api-docs)

## Task Management

- Task lists with CRUD, descriptions, and summary stats (progress bar, counts)
- Task items with completion toggle, assignment, filters (all / completed / incomplete)
- Move tasks between lists
- My Tasks — personal view of assigned items with filters
- Comments on task items and task lists (polymorphic, author-scoped)
- Full-text search across lists and items, and comments.

## Collaboration

- Invite users via email (Mailpit in development)
- Multi-member accounts with owner/collaborator roles
- In-app notifications (invitations, transfers)
- Account switcher — switch between personal and shared workspaces
- Task list transfers between accounts (accept / reject flow)

## Auth & Settings

- Sign up / sign in / sign out / password reset (email-based)
- Profile management (username, password change)
- API token generation for REST API access
- Account settings (rename, manage members, invitations)
- Account deletion (danger zone)

## API Documentation

The REST API is documented live inside the application — browsable by section, with a raw markdown export.

---

## Screenshots

Screenshots of the v2 web application. Captured automatically via Playwright — run `mise run e2e:web:screenshots` (requires a running server) to refresh them.

> Note: Responsive layout — desktop sidebar + mobile bottom nav.

### Sign in

<img src="./screenshots/001_sign_in.png" width="400"/>
<img src="./screenshots/002_sign_in_error.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Sign up

<img src="./screenshots/003_sign_up.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Forgot password

<img src="./screenshots/004_forgot_password.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Task Lists

<img src="./screenshots/010_task_lists.png" width="400"/>
<img src="./screenshots/011_new_task_list.png" width="400"/>
<img src="./screenshots/012_task_list_created.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Task Items

<img src="./screenshots/020_new_task_item.png" width="400"/>
<img src="./screenshots/021_task_items.png" width="400"/>
<img src="./screenshots/022_task_item_show.png" width="400"/>
<img src="./screenshots/023_task_item_completed.png" width="400"/>
<img src="./screenshots/024_task_items_incomplete.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### My Tasks

<img src="./screenshots/030_my_tasks.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Search

<img src="./screenshots/040_search.png" width="400"/>
<img src="./screenshots/041_search_results.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Notifications

<img src="./screenshots/050_notifications.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### Settings

<img src="./screenshots/060_settings.png" width="400"/>
<img src="./screenshots/061_settings_profile.png" width="400"/>
<img src="./screenshots/062_settings_token.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>

### API Docs

<img src="./screenshots/070_api_docs.png" width="400"/>
<img src="./screenshots/071_api_docs_task_lists.png" width="400"/>

<p align="right"><a href="#-table-of-contents-">⬆ back to top</a></p>
