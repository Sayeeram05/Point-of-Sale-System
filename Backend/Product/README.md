# Products API

This document describes the Products API for frontend integration: endpoints, request/response shapes, examples, and integration notes.

Base paths (replace HOST accordingly):
- `GET    /products/`
- `POST   /products/create/`
- `GET    /products/<id>/`
- `PUT    /products/<id>/update/`
- `DELETE /products/<id>/delete/`
- `GET    /products/category/<category_id>/`

## Model

- Product: `ID`, `Name`, `Price`, `ProductCategory` (FK), `Deleted`

Product serializer includes all fields. Views filter `Deleted=False` for reads.

## Endpoints

- GET /products/
  - Returns: 200 OK with JSON array of products (only products where `Deleted=false`).
  - If no products found: 404 with `{ "message": "No products found" }`.

- GET /products/<id>/
  - Returns product details if not deleted. 200 OK or 404 Not Found.

- GET /products/category/<category_id>/
  - Returns products for a category (non-deleted). 200 OK or 404 with `{ "message": "No products found for this category" }`.

- POST /products/create/
  - Creates a product. Request body keys:
    - `Name` (string), `Price` (decimal as string/number), `category` (integer category id).
  - Note: the create view expects the category id under the key `category` (not `ProductCategory`).
  - Success: 201 Created with created product JSON.

- PUT /products/<id>/update/
  - Updates an existing product. Request body should include `Name`, `Price`, and `ProductCategory` (integer id).
  - Note: update expects the category id under the key `ProductCategory` (different from create).

- DELETE /products/<id>/delete/
  - Soft-delete: sets `Deleted = true`. Returns 204 No Content.

## Integration notes & gotchas

- Field key inconsistency: `POST` uses `category`, `PUT` uses `ProductCategory`. Use correct key per HTTP method.
- Decimal fields are serialized as strings. Send values that parse to decimal.
- Empty-list responses return 404 with a message — handle both 200 arrays and 404 message bodies.

## Quick curl examples

Replace `http://HOST` with your server root.

- Create product:

```bash
curl -X POST http://HOST/products/create/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Widget","Price":"199.99","category":2}'
```

- Update product (note `ProductCategory` key):

```bash
curl -X PUT http://HOST/products/5/update/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Widget Pro","Price":"219.99","ProductCategory":3}'
```

- Get products by category:

```bash
curl http://HOST/products/category/2/
```

## Files
- Views: `views.py`
- Serializers: `serializers.py`
- Models: `models.py`

See repository paths for implementation details.
