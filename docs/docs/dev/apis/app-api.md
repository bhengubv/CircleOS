# App Catalogue API

Base URL: `https://api.slepton.co.za`

---

## GET /api/apps

List apps in the catalogue.

**Auth:** None

**Query params:**
- `page` — page number (default 1)
- `page_size` — results per page (default 20, max 100)
- `category` — filter by category
- `search` — search query
- `sort` — `rating` / `installs` / `newest` (default `rating`)
- `free_only` — `true` / `false`

**Response 200:**
```json
{
  "page": 1,
  "total": 847,
  "apps": [
    {
      "id": 42,
      "package_name": "co.za.example.app",
      "name": "Example App",
      "category": "utilities",
      "icon_url": "...",
      "price_sdpkt": 0,
      "rating": 4.7,
      "install_count": 12400,
      "privacy_score": 82
    }
  ]
}
```

---

## GET /api/apps/{id}

Get full app details.

**Response 200:** Full app object including screenshots, description, permissions list, privacy score breakdown.

---

## GET /api/apps/search

Search the catalogue.

**Query params:**
- `q` — search query (min 2 chars)

---

## POST /api/developer/apps

Submit a new app for review.

**Auth:** `Authorization: Bearer <dev_token>`

See [App Submission Guide](../app-submission.md) for field details.

**Response 201:**
```json
{
  "app_id": 99,
  "status": "scanning",
  "privacy_score": null,
  "review_eta": "2026-02-18T12:00:00Z"
}
```

---

## GET /api/developer/apps/{id}/status

Get review status for your app.

**Auth:** `Authorization: Bearer <dev_token>`

**Response 200:**
```json
{
  "app_id": 99,
  "status": "published",
  "privacy_score": 74,
  "published_at": "2026-02-18T12:30:00Z"
}
```

Statuses: `scanning` → `review_pending` → `approved` → `published` (or `rejected`).
