# My Tasks

Returns all task items assigned to you across the account.

## List my tasks

`GET /task/item/assignments.json`

Optional `filter` query param: `incomplete`, `completed` (default: all)

```bash
curl "<%= request.base_url %>/task/item/assignments.json?filter=incomplete" \
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
      "name": "Review pull request",
      "description": null,
      "completed_at": null,
      "created_at": "2026-03-08T03:13:38.127Z",
      "updated_at": "2026-03-08T03:13:38.127Z",
      "task_list_id": 42
    }
  ],
  "filter": "incomplete",
  "counts": {
    "all": 5,
    "incomplete": 3,
    "completed": 2
  },
  "url": "http://example.com/task/item/assignments.json"
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `401` | Missing or invalid API token |
