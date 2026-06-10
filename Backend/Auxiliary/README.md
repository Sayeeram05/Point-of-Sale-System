# Auxiliary App API Documentation

This README describes the Auxiliary app REST API endpoints, request payloads, and response payloads for frontend developers.

## Base URL

The project currently mounts API routes under `api/` in `Backend/Main/urls.py` for the Category app.

If you also mount Auxiliary routes in the same way, the base prefix should be:

```text
/api/
```

A recommended mount point for Auxiliary is:

```python
path('api/', include('Auxiliary.urls')),
```

If the backend runs at `http://localhost:8000`, the API base becomes:

```text
http://localhost:8000/api/
```

---

## Overview

The Auxiliary app exposes two resource groups:

- `color` — stores color values as hex codes.
- `emoji` — stores emoji characters as text.

Each resource supports:

- `GET` list
- `POST` create
- `PUT` update by ID
- `DELETE` delete by ID

---

## Color Endpoints

### List colors

- URL: `GET /api/color/`
- Description: Return the list of all colors.
- Request body: none
- Success response: `200 OK`

Example response:

```json
[
  {
    "ID": 1,
    "HexCode": "#FF5733"
  },
  {
    "ID": 2,
    "HexCode": "#00CC66"
  }
]
```

If no colors exist, the response is:

```json
{
  "message": "No colors found"
}
```

and the status code is `404 Not Found`.

---

### Create a color

- URL: `POST /api/color/create/`
- Description: Add a new color.
- Request body: JSON
- Success response: `201 Created`
- Error response: `400 Bad Request`

Required field:

- `HexCode` (string) — a color code such as `#FFFFFF`.

Example request:

```json
{
  "HexCode": "#123ABC"
}
```

Example success response:

```json
{
  "ID": 3,
  "HexCode": "#123ABC"
}
```

Example error response when the color already exists:

```json
{
  "message": "Color with this hex code already exists"
}
```

Example validation error response:

```json
{
  "HexCode": [
    "This field is required."
  ]
}
```

---

### Update a color

- URL: `PUT /api/color/<id>/update/`
- Description: Update the color record with the provided `id`.
- Request body: JSON
- Success response: `200 OK`
- Error responses: `400 Bad Request`, `404 Not Found`

Example request:

```json
{
  "HexCode": "#000000"
}
```

Example success response:

```json
{
  "ID": 2,
  "HexCode": "#000000"
}
```

If the color ID does not exist, the response status code is `404 Not Found` with no body.

---

### Delete a color

- URL: `DELETE /api/color/<id>/delete/`
- Description: Remove the color record with the provided `id`.
- Request body: none
- Success response: `204 No Content`
- Error response: `404 Not Found`

If the color ID does not exist, the response status code is `404 Not Found` with no body.

---

## Emoji Endpoints

### List emojis

- URL: `GET /api/emoji/`
- Description: Return the list of all emojis.
- Request body: none
- Success response: `200 OK`

Example response:

```json
[
  {
    "ID": 1,
    "Emoji": "😊"
  },
  {
    "ID": 2,
    "Emoji": "🚀"
  }
]
```

If no emojis exist, the response is:

```json
{
  "message": "No emojis found"
}
```

and the status code is `404 Not Found`.

---

### Create an emoji

- URL: `POST /api/emoji/create/`
- Description: Add a new emoji.
- Request body: JSON
- Success response: `201 Created`
- Error response: `400 Bad Request`

Required field:

- `Emoji` (string) — a single emoji character, or a short emoji sequence.

Example request:

```json
{
  "Emoji": "🎉"
}
```

Example success response:

```json
{
  "ID": 3,
  "Emoji": "🎉"
}
```

Example duplicate error response:

```json
{
  "message": "Emoji with this unicode already exists"
}
```

Example validation error response:

```json
{
  "Emoji": [
    "This field is required."
  ]
}
```

---

### Update an emoji

- URL: `PUT /api/emoji/<id>/update/`
- Description: Update the emoji record with the provided `id`.
- Request body: JSON
- Success response: `200 OK`
- Error responses: `400 Bad Request`, `404 Not Found`

Example request:

```json
{
  "Emoji": "🔥"
}
```

Example success response:

```json
{
  "ID": 2,
  "Emoji": "🔥"
}
```

If the emoji ID does not exist, the response status code is `404 Not Found` with no body.

---

### Delete an emoji

- URL: `DELETE /api/emoji/<id>/delete/`
- Description: Remove the emoji record with the provided `id`.
- Request body: none
- Success response: `204 No Content`
- Error response: `404 Not Found`

If the emoji ID does not exist, the response status code is `404 Not Found` with no body.

---

## Data model fields

### Color model

- `ID` (integer): primary key
- `HexCode` (string): the color code value, e.g. `#FF0000`

### Emoji model

- `ID` (integer): primary key
- `Emoji` (string): an emoji character or short emoji sequence

These models are defined in `Auxiliary/models.py`.

---

## Frontend integration notes

- For listing options, call `GET /api/color/` and `GET /api/emoji/`.
- For creating values, call `POST /api/color/create/` or `POST /api/emoji/create/`.
- For updating values, call `PUT /api/color/<id>/update/` or `PUT /api/emoji/<id>/update/`.
- For deleting values, call `DELETE /api/color/<id>/delete/` or `DELETE /api/emoji/<id>/delete/`.
- Send JSON bodies with `Content-Type: application/json`.
- Use the returned `ID` values from list responses to update or delete specific records.

### Example JavaScript requests

```js
// Get all colors
fetch('/api/color/')
  .then(res => res.json())
  .then(data => console.log(data));

// Create a color
fetch('/api/color/create/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ HexCode: '#1A2B3C' })
});

// Update a color
fetch('/api/color/5/update/', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ HexCode: '#FFFFFF' })
});

// Delete a color
fetch('/api/color/5/delete/', {
  method: 'DELETE'
});

// Create an emoji
fetch('/api/emoji/create/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ Emoji: '😊' })
});
```

---

## Important implementation note

The current model classes in `Auxiliary/models.py` use `__str__()` returning `self.Name`, but the fields are `HexCode` and `Emoji`. This should be fixed for correctness, for example:

```python
def __str__(self):
    return self.HexCode
```

or

```python
def __str__(self):
    return self.Emoji
```

---

## File references

- `Auxiliary/urls.py` — route definitions
- `Auxiliary/views.py` — request handling
- `Auxiliary/serializers.py` — serializer fields
- `Auxiliary/models.py` — database models
