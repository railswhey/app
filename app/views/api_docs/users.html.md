# Users

User registration, authentication, and account management. These endpoints do not require authentication unless noted.

## Register

`POST /users.json`

```bash
curl -X POST <%= request.base_url %>/users.json \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"you@example.com","username":"you","password":"Secret!123","password_confirmation":"Secret!123"}}'
```

**Request body:**

```json
{ "user": { "email": "you@example.com", "username": "you", "password": "Secret!123", "password_confirmation": "Secret!123" } }
```

**Response:** `201 Created`

```json
{ "status": "success", "type": "object", "data": { "user_token": "<token>" } }
```

**Errors:** `422` — email/username taken or blank, passwords don't match.

---

## Login

`POST /users/session.json`

```bash
curl -X POST <%= request.base_url %>/users/session.json \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"you@example.com","password":"Secret!123"}}'
```

**Request body:**

```json
{ "user": { "email": "you@example.com", "password": "Secret!123" } }
```

**Response:** `200 OK`

```json
{ "status": "success", "type": "object", "data": { "user_token": "<token>" } }
```

**Errors:** `401` — invalid credentials.

---

## Refresh token

`PUT /users/token.json` — **Requires auth**

```bash
curl -X PUT <%= request.base_url %>/users/token.json \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Response:** `200 OK`

```json
{ "status": "success", "type": "object", "data": { "user_token": "<new_token>" } }
```

---

## Update profile / change password

`PUT /users/profile.json` — **Requires auth**

```bash
curl -X PUT <%= request.base_url %>/users/profile.json \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"user":{"current_password":"Secret!123","password":"NewSecret!456","password_confirmation":"NewSecret!456"}}'
```

**Request body:**

```json
{ "user": { "current_password": "Secret!123", "password": "NewSecret!456", "password_confirmation": "NewSecret!456" } }
```

**Response:** `200 OK`

```json
{ "status": "success" }
```

**Errors:** `422` — wrong `current_password`, passwords don't match, or blank.

---

## Request password reset

`POST /users/password.json`

Always returns `200 OK` even if the email is not found (prevents user enumeration).

```bash
curl -X POST <%= request.base_url %>/users/password.json \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"you@example.com"}}'
```

**Request body:**

```json
{ "user": { "email": "you@example.com" } }
```

**Response:** `200 OK`

```json
{ "status": "success" }
```

---

## Reset password via token

`PUT /users/:token/password.json`

```bash
curl -X PUT <%= request.base_url %>/users/<reset_token>/password.json \
  -H "Content-Type: application/json" \
  -d '{"user":{"password":"NewSecret!456","password_confirmation":"NewSecret!456"}}'
```

**Request body:**

```json
{ "user": { "password": "NewSecret!456", "password_confirmation": "NewSecret!456" } }
```

**Response:** `200 OK`

```json
{ "status": "success" }
```

**Errors:** `422` — invalid or expired token, passwords don't match.

---

## Delete account

`DELETE /users.json` — **Requires auth**

```bash
curl -X DELETE <%= request.base_url %>/users.json \
  -H "Authorization: Bearer <token>"
```

**Response:** `204 No Content`
