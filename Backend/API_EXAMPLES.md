# API Examples and Postman Collection

This file contains ready-to-run curl scripts and a Postman collection to test the Product and Order endpoints.

## curl snippets

Replace `http://HOST` with your server root.

-- List products

```bash
curl -X GET http://HOST/products/
```

-- Get product detail

```bash
curl -X GET http://HOST/products/5/
```

-- Create product

```bash
curl -X POST http://HOST/products/create/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Widget","Price":"199.99","category":2}'
```

-- Update product

```bash
curl -X PUT http://HOST/products/5/update/ \
  -H "Content-Type: application/json" \
  -d '{"Name":"Widget Pro","Price":"219.99","ProductCategory":3}'
```

-- Delete product

```bash
curl -X DELETE http://HOST/products/5/delete/
```

-- List orders

```bash
curl -X GET http://HOST/orders/
# With analytics: hourly/daily/week/month/year grouping
curl -X GET "http://HOST/orders/?date=today"
curl -X GET "http://HOST/orders/?date=this_week"
# Custom range (requires start_date and end_date in YYYY-MM-DD)
curl -X GET "http://HOST/orders/?date=custom&start_date=2026-05-01&end_date=2026-05-07"
```

-- Create order (no items)

```bash
curl -X POST http://HOST/orders/create/ \
  -H "Content-Type: application/json" \
  -d '{"ColorId":1,"TotalQuantity":0,"UpiAmount":"0.00","CashAmount":"0.00","Completed":false}'
```

-- Update order and add items

```bash
curl -X PUT http://HOST/orders/1/update/ \
  -H "Content-Type: application/json" \
  -d '{"OrderItems":[{"ProductID":5,"Quantity":2,"PriceAtPurchase":"49.99"}], "TotalQuantity":2}'
```

-- Patch order

```bash
curl -X PATCH http://HOST/orders/1/patch/ \
  -H "Content-Type: application/json" \
  -d '{"Completed":true}'
```

-- Delete order

```bash
curl -X DELETE http://HOST/orders/1/delete/
```

## Postman / Insomnia

- Import the provided collection file `postman_collection.json` into Postman (File → Import) or into Insomnia as a Postman collection.
- The collection includes prepared requests for list/create/update/delete operations for products and orders.
