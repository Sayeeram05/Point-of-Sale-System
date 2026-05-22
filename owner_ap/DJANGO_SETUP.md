# Django Backend Integration Guide

## Current Status
✅ **Django API Services Created** - Ready to connect to your Django backend
✅ **Service Factory** - Easy switching between mock and real data
✅ **Configuration System** - Centralized API settings

## Quick Setup

### 1. Enable Django API Connection
Edit `lib/config/app_config.dart`:
```dart
static const bool useMockServices = false; // Change to false
```

### 2. Start Your Django Server
```bash
cd Point-of-Sale-System/Backend
python manage.py runserver
```

### 3. Enable CORS (Required for Flutter Web)
Add to your Django `settings.py`:
```python
# Install: pip install django-cors-headers
INSTALLED_APPS = [
    # ... your apps
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    # ... other middleware
]

# Allow Flutter web app to access Django API
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",  # Flutter web dev server
    "http://localhost:8081",
    "http://127.0.0.1:8080",
]

# Or for development only:
CORS_ALLOW_ALL_ORIGINS = True
```

### 4. Install CORS Package
```bash
pip install django-cors-headers
```

### 5. Run Flutter App
```bash
cd Point-of-Sale-System/owner_ap
flutter run -d chrome
```

## API Endpoint Mapping

### Categories
| Flutter Method | Django Endpoint | HTTP Method |
|---------------|----------------|-------------|
| `getCategories()` | `/api/category/` | GET |
| `createCategory()` | `/api/category/create/` | POST |
| `updateCategory()` | `/api/category/{id}/update/` | PUT |
| `deleteCategory()` | `/api/category/{id}/delete/` | DELETE |

### Products
| Flutter Method | Django Endpoint | HTTP Method |
|---------------|----------------|-------------|
| `getProducts()` | `/api/products/` | GET |
| `getProductsByCategory()` | `/api/products/category/{id}/` | GET |
| `createProduct()` | `/api/products/create/` | POST |
| `updateProduct()` | `/api/products/{id}/update/` | PUT |
| `deleteProduct()` | `/api/products/{id}/delete/` | DELETE |

## Data Mapping

### Django → Flutter Category
```python
# Django Model
{
    "ID": 1,
    "Name": "Classic Waffles"
}
```
```dart
// Flutter Model
Category(
    id: "1",
    name: "Classic Waffles",
    icon: "restaurant", // Auto-mapped based on name
    productCount: 0,    // Calculated separately
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
)
```

### Django → Flutter Product
```python
# Django Model
{
    "ID": 1,
    "Name": "Belgian Classic",
    "Price": "120.00",
    "ProductCategory": 1,
    "Deleted": false
}
```
```dart
// Flutter Model
Product(
    id: "1",
    name: "Belgian Classic",
    price: 120.0,
    categoryId: "1",
    isAvailable: true, // !Deleted
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
)
```

## Testing the Connection

### 1. Check Django API Manually
```bash
# Test categories
curl http://localhost:8000/api/category/

# Test products
curl http://localhost:8000/api/products/
```

### 2. Add Sample Data via Django Admin
```bash
python manage.py createsuperuser
python manage.py runserver
# Visit: http://localhost:8000/admin/
```

### 3. Monitor Network Requests
- Open Flutter app in Chrome
- Open Developer Tools → Network tab
- Watch for API calls to `localhost:8000`

## Troubleshooting

### CORS Issues
If you see CORS errors in browser console:
1. Install `django-cors-headers`
2. Add to `INSTALLED_APPS` and `MIDDLEWARE`
3. Set `CORS_ALLOW_ALL_ORIGINS = True` for development

### Connection Refused
- Ensure Django server is running on port 8000
- Check `app_config.dart` has correct `djangoBaseUrl`

### Empty Data
- Add categories and products via Django admin
- Check Django API endpoints return data

### API Errors
- Check Django server logs for errors
- Verify URL patterns in Django `urls.py`
- Ensure serializers are working correctly

## Production Deployment

### 1. Update API URL
```dart
// In app_config.dart
static const String djangoBaseUrl = 'https://your-domain.com/api';
```

### 2. Configure CORS for Production
```python
CORS_ALLOWED_ORIGINS = [
    "https://your-flutter-app.com",
]
```

### 3. Build Flutter Web
```bash
flutter build web
```

## Next Steps

1. **Start Django server**: `python manage.py runserver`
2. **Enable Django API**: Set `useMockServices = false`
3. **Add CORS support**: Install and configure `django-cors-headers`
4. **Test connection**: Run Flutter app and check network requests
5. **Add sample data**: Use Django admin to create categories and products

Your Flutter app is now ready to connect to your Django backend! 🎉