# Orders API Testing Guide

## Setup Instructions

### 1. Start Django Server
```bash
cd Point-of-Sale-System/Backend
python manage.py runserver
```

### 2. Add Sample Data (if not already done)
```bash
# Add categories and products
python add_sample_data.py

# Add sample orders for testing
python add_sample_orders.py
```

### 3. Verify Database
```bash
python manage.py shell
```
```python
from Order.models import Order
from Product.models import Product
print(f"Products: {Product.objects.count()}")
print(f"Orders: {Order.objects.count()}")
```

## API Endpoints for Postman Testing

### Base URL
```
http://localhost:8000/api
```

## 1. Get Orders (Main Endpoint)

### Today's Orders
```
GET http://localhost:8000/api/orders/?date=today
```

### This Week's Orders
```
GET http://localhost:8000/api/orders/?date=this_week
```

### This Month's Orders
```
GET http://localhost:8000/api/orders/?date=this_month
```

### This Year's Orders
```
GET http://localhost:8000/api/orders/?date=this_year
```

### Yesterday's Orders
```
GET http://localhost:8000/api/orders/?date=yesterday
```

### Custom Date Range
```
GET http://localhost:8000/api/orders/?date=custom&start_date=2024-01-01&end_date=2024-01-31
```

### All Orders (no filter)
```
GET http://localhost:8000/api/orders/
```

## Expected Response Format

```json
{
  "summary": {
    "orders_count": 15,
    "total_upi": 1250.0,
    "total_cash": 450.0,
    "total_amount": 1700.0
  },
  "analytics": [
    {
      "period": "2024-01-15T09:00:00Z",
      "orders_count": 2,
      "total_upi": 200.0,
      "total_cash": 100.0
    },
    {
      "period": "2024-01-15T10:00:00Z",
      "orders_count": 3,
      "total_upi": 350.0,
      "total_cash": 150.0
    }
  ],
  "orders": [
    {
      "id": "#ORD-123",
      "date": "2024-01-15T10:30:00Z",
      "items": ["Belgian Classic (1)", "Choco Lava (1)"],
      "total_amount": 300.0,
      "payment_method": "UPI",
      "status": "Completed",
      "customer_name": "Customer 123"
    }
  ]
}
```

## 2. Create Order

```
POST http://localhost:8000/api/orders/create/
Content-Type: application/json

{
  "UpiAmount": 150.0,
  "CashAmount": 0.0,
  "TotalQuantity": 2,
  "Completed": true,
  "ColorId": 1,
  "EmojiId": 1
}
```

## 3. Update Order

```
PUT http://localhost:8000/api/orders/123/update/
Content-Type: application/json

{
  "UpiAmount": 200.0,
  "CashAmount": 50.0,
  "TotalQuantity": 3,
  "Completed": true,
  "OrderItems": [
    {
      "ProductID": 1,
      "Quantity": 2,
      "PriceAtPurchase": 120.0
    },
    {
      "ProductID": 2,
      "Quantity": 1,
      "PriceAtPurchase": 130.0
    }
  ]
}
```

## 4. Delete Order

```
DELETE http://localhost:8000/api/orders/123/delete/
```

## Testing Checklist

### ✅ Basic Functionality
- [ ] GET `/orders/` returns orders list
- [ ] GET `/orders/?date=today` filters today's orders
- [ ] GET `/orders/?date=this_week` filters this week's orders
- [ ] GET `/orders/?date=this_month` filters this month's orders
- [ ] GET `/orders/?date=this_year` filters this year's orders
- [ ] GET `/orders/?date=custom&start_date=2024-01-01&end_date=2024-01-31` works

### ✅ Response Format
- [ ] Response includes `summary` object with counts and totals
- [ ] Response includes `analytics` array with time-based data
- [ ] Response includes `orders` array with individual orders
- [ ] Order objects have all required fields (id, date, items, total_amount, etc.)

### ✅ Error Handling
- [ ] Invalid date parameter returns 400 error
- [ ] Custom date without start_date/end_date returns 400 error
- [ ] Invalid date format returns 400 error
- [ ] Non-existent order ID returns 404 error

### ✅ CRUD Operations
- [ ] POST `/orders/create/` creates new order
- [ ] PUT `/orders/{id}/update/` updates existing order
- [ ] DELETE `/orders/{id}/delete/` deletes order

## Flutter App Integration

The Flutter Orders screen should now:

1. **Connect to real backend** instead of using mock data
2. **Show success/error messages** when loading data
3. **Display actual order counts and revenue** from Django
4. **Filter by date ranges** (Today, Week, Month, Year, Custom)
5. **Show real order items** with product names and quantities
6. **Handle API errors gracefully** with user-friendly messages

## Troubleshooting

### No Orders Showing
1. Check if Django server is running: `http://localhost:8000/api/orders/`
2. Run sample data scripts: `python add_sample_data.py && python add_sample_orders.py`
3. Check Flutter console for API errors
4. Verify CORS settings in Django `settings.py`

### API Errors
1. Check Django console for error messages
2. Verify database migrations: `python manage.py migrate`
3. Check if products exist: `python manage.py shell` → `Product.objects.count()`

### Flutter Connection Issues
1. Verify `AppConfig.djangoBaseUrl` is `http://localhost:8000/api`
2. Check if `useMockServices` is `false`
3. Enable debug logs in `AppConfig.enableDebugLogs = true`
4. Check Flutter console for network errors

## Success Indicators

When everything is working correctly:

1. **Postman**: All API endpoints return proper JSON responses
2. **Flutter App**: Shows "Orders loaded from backend - X orders found" message
3. **Date Filtering**: Clicking Today/Week/Month/Year shows different data
4. **Real Data**: Order cards show actual product names and amounts
5. **No Mock Data**: No fallback to duplicate/demo data

Your Orders API is now fully functional and ready for production use! 🎉