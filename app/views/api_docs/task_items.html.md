# Task Items

## List items in a list

`GET /task_lists/:list_id/task_items.json`

```bash
curl "<%= request.base_url %>/task_lists/1/task_items.json?filter=incomplete" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

`filter` query param: `incomplete`, `completed` (default: all)

**Example response:**

```json
{
  "status": "success",
  "type": "array",
  "data": [
    {
      "id": 1,
      "name": "Test Task",
      "description": "A task",
      "completed_at": null,
      "created_at": "2026-03-08T03:13:38.127Z",
      "updated_at": "2026-03-08T03:13:38.127Z",
      "task_list_id": 1
    }
  ],
  "url": "http://example.com/task_lists/1/task_items.json"
}
```

**Errors:** `404` — list not found.

---

## Get a task item

`GET /task_lists/:list_id/task_items/:id.json`

```bash
curl <%= request.base_url %>/task_lists/1/task_items/5.json \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 5,
    "name": "Test Task",
    "description": "A task",
    "completed_at": null,
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:38.127Z",
    "task_list_id": 1
  },
  "url": "http://example.com/task_lists/1/task_items/5.json"
}
```

**Errors:** `404` — list or item not found.

---

## Create a task item

`POST /task_lists/:list_id/task_items.json`

```bash
curl -X POST <%= request.base_url %>/task_lists/1/task_items.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task_item":{"name":"Task name","description":"Optional","assigned_user_id":null}}'
```

**Request body:**

```json
{ "task_item": { "name": "Task name", "description": "Optional", "assigned_user_id": null } }
```

**Response:** `201 Created`

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "name": "Task name",
    "description": "Optional",
    "completed_at": null,
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:38.127Z",
    "task_list_id": 1
  },
  "url": "http://example.com/task_lists/1/task_items/1.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `400` | Missing `task_item` key in request body |
| `404` | List not found |
| `422` | Name is blank |

---

## Update a task item

`PUT /task_lists/:list_id/task_items/:id.json`

```bash
curl -X PUT <%= request.base_url %>/task_lists/1/task_items/5.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"task_item":{"name":"Updated name"}}'
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 5,
    "name": "Updated name",
    "description": "A task",
    "completed_at": null,
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:39.055Z",
    "task_list_id": 1
  },
  "url": "http://example.com/task_lists/1/task_items/5.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `400` | Missing `task_item` key in request body |
| `404` | List or item not found |
| `422` | Name is blank |

---

## Delete a task item

`DELETE /task_lists/:list_id/task_items/:id.json`

```bash
curl -X DELETE <%= request.base_url %>/task_lists/1/task_items/5.json \
  -H "Authorization: Bearer <token>"
```

**Response:** `204 No Content`

**Errors:** `404` — list or item not found.

---

## Mark complete

`PUT /task_lists/:list_id/task_items/:id/complete.json`

```bash
curl -X PUT <%= request.base_url %>/task_lists/1/task_items/5/complete.json \
  -H "Authorization: Bearer <token>"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 5,
    "name": "Task name",
    "description": "A task",
    "completed_at": "2026-03-08T03:13:39.430Z",
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:39.430Z",
    "task_list_id": 1
  },
  "url": "http://example.com/task_lists/1/task_items/5.json"
}
```

**Errors:** `404` — list or item not found.

---

## Mark incomplete

`PUT /task_lists/:list_id/task_items/:id/incomplete.json`

```bash
curl -X PUT <%= request.base_url %>/task_lists/1/task_items/5/incomplete.json \
  -H "Authorization: Bearer <token>"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 5,
    "name": "Task name",
    "description": "A task",
    "completed_at": null,
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:39.757Z",
    "task_list_id": 1
  },
  "url": "http://example.com/task_lists/1/task_items/5.json"
}
```

**Errors:** `404` — list or item not found.

---

## Move to another list

`PUT /task_lists/:list_id/task_items/:id/move.json`

```bash
curl -X PUT <%= request.base_url %>/task_lists/1/task_items/5/move.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"target_list_id":2}'
```

**Request body:**

```json
{ "target_list_id": 2 }
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 5,
    "name": "Task name",
    "description": "A task",
    "completed_at": null,
    "created_at": "2026-03-08T03:13:38.127Z",
    "updated_at": "2026-03-08T03:13:39.976Z",
    "task_list_id": 2
  },
  "url": "http://example.com/task_lists/2/task_items/5.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `404` | Source list or item not found |
| `422` | `target_list_id` is the same as the current list or does not exist |
