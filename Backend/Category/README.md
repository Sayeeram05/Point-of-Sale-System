# Category App API Documentation

This document describes the `Category` Django REST API endpoints, request payloads, and response payloads for frontend developers.

## Base URL

The backend root path is configured in `Backend/Main/urls.py` as:

```python
path('api/', include('Category.urls')),
```

So the Category API base path is:

```text
/api/category/
```

If the backend is hosted at `http://localhost:8000`, the full API base will be:

```text
http://localhost:8000/api/category/
```

---

## Endpoints

### 1. List All Categories

- URL: `GET /api/category/`
- Description: Retrieve a list of all categories.
- Request Body: None
- Response: 200 OK

Example response:

```json
[
  {
    "ID": 1,
    "Name": "Electronics"
  },
  {
    "ID": 2,
    "Name": "Office Supplies"
  }
]
```

---

### 2. Create a Category

- URL: `POST /api/category/create/`
- Description: Create a new category.
- Request Body: JSON
- Response: 201 Created on success, 400 Bad Request on validation error

Required fields:

- `Name` (string): The category name. Must be unique.

Example request:

```json
{
  "Name": "Stationery"
}
```

Example success response:

```json
{
  "ID": 3,
  "Name": "Stationery"
}
```

Example validation error response:

```json
{
  "Name": [
    "category with this name already exists."
  ]
}
```

---

### 3. Update a Category

- URL: `PUT /api/category/<id>/update/`
- Description: Update the category with the specified ID.
- Request Body: JSON
- Response: 200 OK on success, 400 Bad Request on validation error, 404 Not Found if the category does not exist

Required fields:

- `Name` (string): New name for the category.

Example request:

```json
{
  "Name": "Office Equipment"
}
```

Example success response:

```json
{
  "ID": 2,
  "Name": "Office Equipment"
}
```

Example not found response:

```json
{
  "error": "Category not found"
}
```

---

### 4. Delete a Category

- URL: `DELETE /api/category/<id>/delete/`
- Description: Delete the category with the specified ID.
- Request Body: None
- Response: 204 No Content on success, 404 Not Found if the category does not exist

Example not found response:

```json
{
  "error": "Category not found"
}
```

---

## Data Model

Each category object uses the following fields:

- `ID` (integer): Primary key for the category.
- `Name` (string): Category name.

The serializer is defined in `Category/serializers.py` and exposes only these two fields.

---

## Notes for Frontend Integration

- Use the `GET /api/category/` endpoint to populate category lists, dropdowns, or selection fields.
- Use the `POST /api/category/create/` endpoint when creating a new category from the UI.
- Use the `PUT /api/category/<id>/update/` endpoint to edit an existing category.
- Use the `DELETE /api/category/<id>/delete/` endpoint to remove a category.
- If a category name is not unique during create/update, the API returns a 400 error with validation details.

### Example fetch usage (JavaScript)

```js
// List categories
fetch('/api/category/')
  .then(res => res.json())
  .then(data => console.log(data));

// Create a category
fetch('/api/category/create/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ Name: 'New Category' })
});

// Update a category
fetch('/api/category/5/update/', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ Name: 'Updated Name' })
});

// Delete a category
fetch('/api/category/5/delete/', {
  method: 'DELETE'
});
```

---

## File References

- `Category/models.py` — Category model definition
- `Category/serializers.py` — Category serializer exposing `ID` and `Name`
- `Category/views.py` — API view logic for list, create, update, delete
- `Category/urls.py` — URL routing for category endpoints

---

## Troubleshooting

- If the backend raises a unique validation error on create/update, verify the category name is not already used.
- If a 404 appears on update/delete, confirm the category `ID` exists in the database.
- If the backend is mounted under a different prefix, adjust path prefixes accordingly.
