# Orders API

This document describes the Orders API for frontend integration: endpoints, request/response shapes, examples, and integration notes.

Base paths (replace HOST accordingly):
- `GET    /orders/`
- `POST   /orders/create/`
- `PUT    /orders/<id>/update/`
- `PATCH  /orders/<id>/patch/`
- `DELETE /orders/<id>/delete/`

## Models

- Order: `ID`, `ColorId` (FK), `EmojiId` (FK), `TotalQuantity`, `UpiAmount`, `CashAmount`, `Completed`, `CreatedAt`, `UpdatedAt`
- OrderItem: `ID`, `OrderId` (FK), `ProductID` (FK), `Quantity`, `PriceAtPurchase`

Serializers: `OrderSerializer` includes `OrderItems` as a nested, read-only list. See code in `views.py` and `serializers.py`.

## Endpoints

- GET /orders/
  - Returns: 200 OK with JSON array of orders (each includes `OrderItems`).
  - Example response:

```json
[
  {
    "ID": 1,
    "ColorId": 2,
    "EmojiId": 3,
    "TotalQuantity": 4,
    "UpiAmount": "123.45",
    "CashAmount": "0.00",
    "Completed": false,
    "CreatedAt": "2024-04-01T12:34:56Z",
    "UpdatedAt": "2024-04-01T12:34:56Z",
    "OrderItems": [
      { "ID": 10, "OrderId": 1, "ProductID": 5, "Quantity": 2, "PriceAtPurchase": "49.99" }
    ]
  }
]
```

- POST /orders/create/
  - Creates an Order record. Nested `OrderItems` are ignored on create (read-only).
  - Request body keys (example): `ColorId`, `EmojiId`, `TotalQuantity`, `UpiAmount`, `CashAmount`, `Completed`.
  - Success: 201 Created with created order JSON.

- PUT /orders/<id>/update/
  - Updates order and optionally replaces `OrderItems`.
  - If `OrderItems` array is provided, the server deletes existing items and recreates items from the array.
  - Each item must include `ProductID`, `Quantity`, `PriceAtPurchase`. The server sets `OrderId` automatically.
  - Example request body:

```json
{
  "TotalQuantity": 3,
  "UpiAmount": "50.00",
  "CashAmount": "0.00",
  "Completed": true,
  "OrderItems": [
    { "ProductID": 5, "Quantity": 1, "PriceAtPurchase": "29.99" },
    { "ProductID": 7, "Quantity": 2, "PriceAtPurchase": "10.00" }
  ]
}
```

- PATCH /orders/<id>/patch/
  - Partial update of order fields (use for small updates like toggling `Completed`).

- DELETE /orders/<id>/delete/
  - Permanently deletes the order (cascade deletes OrderItems). Returns 204 No Content.

## Integration notes

- To add items when creating an order: first `POST /orders/create/` to create the order, then `PUT /orders/<id>/update/` with `OrderItems` to add items.
- PUT replaces all existing `OrderItems`. Send the complete desired final items array.
- Decimal fields are serialized as strings (e.g. "49.99"). Send as strings or numbers that parse as decimals.
- IDs are exposed as `ID` (capitalized).
- No authentication is implemented in these views; if auth is added, include appropriate headers.

## Quick curl examples

Replace `http://HOST` with your server root.

- Create an order (no items):

```bash
curl -X POST http://HOST/orders/create/ \
  -H "Content-Type: application/json" \
  -d '{"ColorId":1,"TotalQuantity":0,"UpiAmount":"0.00","CashAmount":"0.00","Completed":false}'
```

- Add items via update:

```bash
curl -X PUT http://HOST/orders/1/update/ \
  -H "Content-Type: application/json" \
  -d '{"OrderItems":[{"ProductID":5,"Quantity":2,"PriceAtPurchase":"49.99"}], "TotalQuantity":2}'
```

## Files
- Views: `views.py`
- Serializers: `serializers.py`
- Models: `models.py`

See repository paths for implementation details.
