# Task Lists

## List all task lists

`GET /task_lists.json`

Returns all task lists for your account.

```bash
curl <%= request.base_url %>/task_lists.json \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "array",
  "data": [
    {
      "id": 1,
      "inbox": true,
      "name": "Inbox",
      "description": "This is your default list, it cannot be deleted.",
      "created_at": "2026-03-08T03:13:35.280Z",
      "updated_at": "2026-03-08T03:13:35.280Z",
      "account_id": 1
    }
  ],
  "url": "http://example.com/task_lists.json"
}
```

---

## Get a task list

`GET /task_lists/:id.json`

```bash
curl <%= request.base_url %>/task_lists/1.json \
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
    "inbox": false,
    "name": "My List",
    "description": "A task list",
    "created_at": "2026-03-08T03:13:36.660Z",
    "updated_at": "2026-03-08T03:13:36.660Z",
    "account_id": 1
  },
  "url": "http://example.com/task_lists/1.json"
}
```

**Errors:** `404` — list not found or not owned by your account.

---

## Create a task list

`POST /task_lists.json`

```bash
curl -X POST <%= request.base_url %>/task_lists.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task_list":{"name":"My List","description":"Optional"}}'
```

**Request body:**

```json
{ "task_list": { "name": "My List", "description": "Optional" } }
```

**Response:** `201 Created`

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 2,
    "inbox": false,
    "name": "My List",
    "description": "Optional",
    "created_at": "2026-03-08T03:13:36.660Z",
    "updated_at": "2026-03-08T03:13:36.660Z",
    "account_id": 1
  },
  "url": "http://example.com/task_lists/2.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `400` | Missing `task_list` key in request body |
| `422` | Name is blank |

---

## Update a task list

`PUT /task_lists/:id.json`

```bash
curl -X PUT <%= request.base_url %>/task_lists/1.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task_list":{"name":"Renamed List"}}'
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "inbox": false,
    "name": "Renamed List",
    "description": "Optional",
    "created_at": "2026-03-08T03:13:36.660Z",
    "updated_at": "2026-03-08T03:13:37.245Z",
    "account_id": 1
  },
  "url": "http://example.com/task_lists/1.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `400` | Missing `task_list` key in request body |
| `403` | Inbox list cannot be modified |
| `404` | List not found |
| `422` | Name is blank |

---

## Delete a task list

`DELETE /task_lists/:id.json`

```bash
curl -X DELETE <%= request.base_url %>/task_lists/1.json \
  -H "Authorization: Bearer <token>"
```

**Response:** `204 No Content`

**Errors:**

| Code | Reason |
|------|--------|
| `403` | Inbox list cannot be deleted |
| `404` | List not found |
