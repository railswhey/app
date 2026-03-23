# Search

Full-text search across task items and task lists in your account.

## Search

`GET /search.json?q=keyword`

Minimum 2 characters. Returns up to 20 task items and 10 task lists.

```bash
curl "<%= request.base_url %>/search.json?q=project" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "query": "project",
  "data": {
    "task_items": [
      {
        "id": 1,
        "name": "Project kickoff",
        "description": null,
        "completed_at": null,
        "created_at": "2026-03-08T03:13:38.127Z",
        "updated_at": "2026-03-08T03:13:38.127Z",
        "task_list_id": 42
      }
    ],
    "task_lists": [
      {
        "id": 42,
        "inbox": false,
        "name": "Project Alpha",
        "description": "Main project list",
        "created_at": "2026-03-08T03:13:35.280Z",
        "updated_at": "2026-03-08T03:13:35.280Z",
        "account_id": 1
      }
    ]
  },
  "url": "http://example.com/search.json"
}
```

When `q` is absent or shorter than 2 characters, `data.task_items` and `data.task_lists` are empty arrays.

**Errors:**

| Code | Reason |
|------|--------|
| `401` | Missing or invalid API token |
