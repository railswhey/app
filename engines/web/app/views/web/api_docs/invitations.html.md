# Invitations

## List invitations

`GET /account/invitations.json`

Returns all pending invitations for your account.

```bash
curl <%= request.base_url %>/account/invitations.json \
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
      "email": "user@example.com",
      "token": "AbCdEfGhIjKlMnOpQrSt1234",
      "accepted_at": null,
      "created_at": "2026-03-08T03:13:41.533Z",
      "updated_at": "2026-03-08T03:13:41.533Z"
    }
  ]
}
```

---

## Send an invitation

`POST /account/invitations.json`

```bash
curl -X POST <%= request.base_url %>/account/invitations.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"invitation":{"email":"user@example.com"}}'
```

**Request body:**

```json
{ "invitation": { "email": "user@example.com" } }
```

**Response:** `201 Created`

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "accepted_at": null,
    "created_at": "2026-03-08T03:13:41.533Z",
    "updated_at": "2026-03-08T03:13:41.533Z"
  }
}
```

**Errors:**

| Code | Reason |
|------|--------|
| `400` | Missing `invitation` key in request body |
| `422` | Invalid email format, already invited, or user is already a member |

---

## Show invitation

`GET /invitations/:token.json`

```bash
curl <%= request.base_url %>/invitations/<token>.json \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "accepted_at": null,
    "created_at": "2026-03-08T03:13:41.533Z",
    "updated_at": "2026-03-08T03:13:41.533Z"
  }
}
```

**Errors:** `404` — token not found or already accepted.

---

## Accept invitation

`PATCH /invitations/:token.json`

```bash
curl -X PATCH <%= request.base_url %>/invitations/<token>.json \
  -H "Accept: application/json"
```

**Example response:**

```json
{
  "status": "success",
  "type": "object",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "token": "AbCdEfGhIjKlMnOpQrSt1234",
    "accepted_at": "2026-03-08T03:13:42.105Z",
    "created_at": "2026-03-08T03:13:41.533Z",
    "updated_at": "2026-03-08T03:13:41.533Z"
  }
}
```

**Errors:** `404` — token not found or already accepted.

---

## Delete invitation

`DELETE /account/invitations/:id.json`

```bash
curl -X DELETE <%= request.base_url %>/account/invitations/7.json \
  -H "Authorization: Bearer <token>"
```

**Response:** `204 No Content`

**Errors:**

| Code | Reason |
|------|--------|
| `404` | Invitation not found |
