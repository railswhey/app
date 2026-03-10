# Task List Transfers

Transfer a task list to another user's account. Requires approval from the target account owner/admin.

## Request a transfer

`POST /task_lists/:list_id/transfer.json`

```bash
curl -X POST <%= request.base_url %>/task_lists/1/transfer.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task_list_transfer":{"to_email":"other@example.com"}}'
```

**Request body:**

```json
{ "task_list_transfer": { "to_email": "other@example.com" } }
```

**Response:** `201 Created`

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "status": "pending",
    "task_list_id": 1,
    "from_account_id": 1,
    "to_account_id": 2,
    "created_at": "2026-03-08T03:13:47.480Z",
    "updated_at": "2026-03-08T03:13:47.480Z"
  }
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `404` | List not found |
| `422` | Unknown email, transferring to yourself, or list already has a pending transfer |

---

## Show transfer

`GET /transfers/:token.json`

```bash
curl <%= request.base_url %>/transfers/<token>.json \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "status": "pending",
    "task_list_id": 1,
    "from_account_id": 1,
    "to_account_id": 2,
    "created_at": "2026-03-08T03:13:47.480Z",
    "updated_at": "2026-03-08T03:13:47.480Z"
  }
}
```

**Errors:** `404` — token not found.

---

## Accept or reject

`PATCH /transfers/:token.json`

**Accept:**

```bash
curl -X PATCH <%= request.base_url %>/transfers/<token>.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action_type":"accept"}'
```

**Reject:**

```bash
curl -X PATCH <%= request.base_url %>/transfers/<token>.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action_type":"reject"}'
```

**Request body:**

```json
{ "action_type": "accept" }
```

```json
{ "action_type": "reject" }
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "status": "accepted",
    "task_list_id": 1,
    "from_account_id": 1,
    "to_account_id": 2,
    "created_at": "2026-03-08T03:13:47.480Z",
    "updated_at": "2026-03-08T03:13:47.841Z"
  }
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `404` | Token not found |
| `422` | Transfer already accepted or rejected |
