# Members

## List members

`GET /account/memberships.json`

Returns all members of your account.

```bash
curl <%= request.base_url %>/account/memberships.json \
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
      "role": "owner",
      "created_at": "2026-03-08T03:13:35.274Z",
      "updated_at": "2026-03-08T03:13:35.274Z",
      "user": {
        "id": 1,
        "email": "you@example.com",
        "username": "you"
      }
    }
  ]
}
```

---

## Remove a member

`DELETE /account/memberships/:id.json`

```bash
curl -X DELETE <%= request.base_url %>/account/memberships/3.json \
  -H "Authorization: Bearer <token>"
```

**Response:** `204 No Content`

**Errors:**

| Code | Reason |
|------|--------|
| `404` | Membership not found |

Note: Only owners and admins can remove members.
