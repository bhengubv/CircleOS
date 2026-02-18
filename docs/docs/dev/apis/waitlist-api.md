# Waitlist API

Base URL: `https://api.slepton.co.za`

Used by the Circle OS website to join and query the device waitlist.

---

## POST /api/circle/waitlist

Join the waitlist for a specific device.

**Auth:** None

```json
{
  "email": "user@example.com",
  "device_brand": "samsung",
  "device_model": "Galaxy A52",
  "country": "ZA",
  "is_developer": false,
  "device_supported": true,
  "features_viewed": [0, 1, 3],
  "time_spent_secs": 47,
  "referrer": "instagram"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "You're on the list! We'll email you when Circle OS is ready for your device.",
  "total_count": 4821
}
```

If the email already exists, the device preference is updated.

---

## GET /api/circle/waitlist/count

Get waitlist statistics.

**Auth:** None

**Response 200:**
```json
{
  "total": 4821,
  "by_device": {
    "Samsung Galaxy A52": 1203,
    "Xiaomi Redmi Note 10": 987,
    "Nokia G21": 412
  }
}
```

---

## GET /api/circle/devices

Get the full device compatibility catalogue.

**Auth:** None

**Response 200:**
```json
{
  "brands": [
    {
      "id": "samsung",
      "name": "Samsung",
      "devices": [
        {
          "brand": "samsung",
          "brand_name": "Samsung",
          "model": "Galaxy A52",
          "supported": true,
          "expected_date": null
        },
        {
          "brand": "samsung",
          "brand_name": "Samsung",
          "model": "Galaxy A51",
          "supported": false,
          "expected_date": "Q2 2026"
        }
      ]
    }
  ]
}
```

---

## GET /api/circle/devices/{brand}/{model}

Get details for a specific device.

**Auth:** None

**Example:** `GET /api/circle/devices/samsung/Galaxy%20A52`

**Response 200:**
```json
{
  "brand": "samsung",
  "brand_name": "Samsung",
  "model": "Galaxy A52",
  "supported": true,
  "expected_date": null,
  "waitlist_count": 1203
}
```

**Response 404:** Device not in catalogue.
