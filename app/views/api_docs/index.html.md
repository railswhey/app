# Rails Whey App API

## Overview

REST JSON API. Authenticate with Bearer token from your profile settings.

## Base URL

```
<%= request.base_url %>
```

## Authentication

Include `Authorization: Bearer <token>` in every request.

## Response format

```json
{ "status": "success", "type": "object|array", "data": {} }
{ "status": "failure", "type": "object", "data": { "message": "...", "details": {} } }
{ "status": "error", "type": "object", "data": { "message": "..." } }
```

