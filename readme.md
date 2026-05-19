# Django Revision Guide

## Introduction

This README is a complete beginner-friendly Django revision guide with practical examples and step-by-step explanations. It covers:

* Django setup
* Project creation
* App creation
* Models
* Migrations
* Admin panel
* Django REST Framework (DRF)
* Serializers
* API methods (GET, POST, PUT, PATCH, DELETE)
* Generic APIs
* ViewSets
* Routers
* Status codes

---

# 1. Install Django and Django REST Framework

## Install Django

Open terminal or PowerShell and run:

```bash
pip install django
```

## Install Django REST Framework

```bash
pip install djangorestframework
```

### Verify Installation

```bash
python -m django --version
```

---

# 2. Create a Django Project

## Command

```bash
django-admin startproject project_name
```

### Example

```bash
django-admin startproject billing_system
```

This creates the following structure:

```text
billing_system/
│
├── manage.py
├── billing_system/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
```

---

# 3. Move Into the Project Folder

```bash
cd billing_system
```

---

# 4. Run the Django Server

## Command

```bash
py manage.py runserver
```

### Output

```text
Starting development server at http://127.0.0.1:8000/
```

Open browser:

```text
http://127.0.0.1:8000/
```

You will see the Django welcome page.

---

# 5. Add Django REST Framework

Open:

```text
settings.py
```

Find:

```python
INSTALLED_APPS = [
]
```

Add:

```python
'rest_framework',
```

Example:

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'rest_framework',
]
```

---

# 6. Initial Database Migration

## Create Migration Files

```bash
py manage.py makemigrations
```

## Apply Migrations

```bash
py manage.py migrate
```

### What is Migration?

Migration converts Python model changes into database tables.

---

# 7. Create a Django App

## Command

```bash
py manage.py startapp app_name
```

### Example

```bash
py manage.py startapp products
```

Folder structure:

```text
products/
│
├── admin.py
├── apps.py
├── models.py
├── views.py
├── tests.py
└── migrations/
```

---

# 8. Add App in settings.py

Open:

```text
settings.py
```

Add app name:

```python
INSTALLED_APPS = [
    'rest_framework',
    'products',
]
```

---

# 9. Create Models

Models are used to create database tables.

Open:

```text
products/models.py
```

Example:

```python
from django.db import models

class Product(models.Model):
    name = models.CharField(max_length=100)
    price = models.IntegerField()
    quantity = models.IntegerField()

    def __str__(self):
        return self.name
```

---

# 10. Create Migrations for Models

## Create Migration

```bash
py manage.py makemigrations
```

## Apply Migration

```bash
py manage.py migrate
```

This creates the Product table in the database.

---

# 11. Create Superuser

Superuser is used to access Django admin panel.

## Command

```bash
py manage.py createsuperuser
```

Enter:

* Username
* Email
* Password

---

# 12. Register Models in Admin Panel

Open:

```text
products/admin.py
```

Add:

```python
from django.contrib import admin
from .models import Product

admin.site.register(Product)
```

---

# 13. Access Admin Panel

Run server:

```bash
py manage.py runserver
```

Open:

```text
http://127.0.0.1:8000/admin
```

Login with superuser credentials.

Now you can:

* Add products
* Edit products
* Delete products
* Manage database visually

---

# 14. Django REST Framework (DRF)

DRF is used to create APIs.

APIs allow frontend and backend communication.

---

# 15. Create Serializer

Serializer converts model data into JSON format.

Create file:

```text
products/serializers.py
```

Add:

```python
from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'
```

---

# 16. Understanding API Methods

## GET

Used to fetch data.

Example:

```text
Get all products
```

---

## POST

Used to create data.

Example:

```text
Add new product
```

---

## PUT

Used to completely update data.

Example:

```text
Update all product fields
```

---

## PATCH

Used to partially update data.

Example:

```text
Update only price
```

---

## DELETE

Used to remove data.

Example:

```text
Delete product
```

---

# 17. Function Based API Example

Open:

```text
products/views.py
```

## GET and POST Example

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Product
from .serializers import ProductSerializer

@api_view(['GET', 'POST'])
def product_list(request):

    if request.method == 'GET':
        products = Product.objects.all()
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data)

    if request.method == 'POST':
        serializer = ProductSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors)
```

---

# 18. URL Configuration

Create:

```text
products/urls.py
```

Add:

```python
from django.urls import path
from .views import product_list

urlpatterns = [
    path('products/', product_list),
]
```

---

# 19. Connect App URLs to Main URLs

Open:

```text
billing_system/urls.py
```

Add:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('products.urls')),
]
```

---

# 20. Test API

Run server:

```bash
py manage.py runserver
```

Open:

```text
http://127.0.0.1:8000/products/
```

You will see JSON data.

---

# 21. PUT, PATCH, DELETE Example

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Product
from .serializers import ProductSerializer

@api_view(['PUT', 'PATCH', 'DELETE'])
def product_detail(request, pk):

    product = Product.objects.get(id=pk)

    if request.method == 'PUT':
        serializer = ProductSerializer(product, data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

    if request.method == 'PATCH':
        serializer = ProductSerializer(product, data=request.data, partial=True)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

    if request.method == 'DELETE':
        product.delete()
        return Response({'message': 'Deleted Successfully'})
```

---

# 22. Generic APIs

Generic APIs reduce code.

Open:

```text
views.py
```

```python
from rest_framework import generics
from .models import Product
from .serializers import ProductSerializer

class ProductListCreate(generics.ListCreateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
```

### What This Does

* GET → Fetch all products
* POST → Create product

Automatically handled.

---

# 23. Generic API URLs

```python
from django.urls import path
from .views import ProductListCreate

urlpatterns = [
    path('products/', ProductListCreate.as_view()),
]
```

---

# 24. ModelViewSet

ModelViewSet automatically handles:

* GET
* POST
* PUT
* PATCH
* DELETE

Example:

```python
from rest_framework import viewsets
from .models import Product
from .serializers import ProductSerializer

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
```

---

# 25. Routers

Routers automatically create URLs.

Open:

```text
products/urls.py
```

```python
from rest_framework.routers import DefaultRouter
from .views import ProductViewSet

router = DefaultRouter()
router.register('products', ProductViewSet)

urlpatterns = router.urls
```

Now Django automatically creates:

```text
/products/
/products/1/
```

---

# 26. Status Codes

Status codes tell whether request succeeded or failed.

## Common Status Codes

| Status Code | Meaning              |
| ----------- | -------------------- |
| 200         | Success              |
| 201         | Created Successfully |
| 400         | Bad Request          |
| 401         | Unauthorized         |
| 403         | Forbidden            |
| 404         | Not Found            |
| 500         | Server Error         |

---

# 27. Using Status Codes in DRF

```python
from rest_framework import status
from rest_framework.response import Response

return Response(serializer.data, status=status.HTTP_201_CREATED)
```

Example:

```python
return Response({'message': 'Deleted'}, status=status.HTTP_200_OK)
```

---

# 28. Complete Project Flow

## Step-by-Step Flow

### Step 1

Install Django and DRF

```bash
pip install django djangorestframework
```

### Step 2

Create Project

```bash
django-admin startproject billing_system
```

### Step 3

Move into project

```bash
cd billing_system
```

### Step 4

Create app

```bash
py manage.py startapp products
```

### Step 5

Add app and rest_framework in settings.py

### Step 6

Create models

### Step 7

Run migrations

```bash
py manage.py makemigrations
py manage.py migrate
```

### Step 8

Create serializers

### Step 9

Create views

### Step 10

Create URLs

### Step 11

Run server

```bash
py manage.py runserver
```

---

# 29. Important Django Files

| File           | Purpose                  |
| -------------- | ------------------------ |
| settings.py    | Project settings         |
| urls.py        | URL routing              |
| models.py      | Database tables          |
| views.py       | Business logic           |
| serializers.py | Convert model to JSON    |
| admin.py       | Register models in admin |
| manage.py      | Django management tool   |

---

# 30. Useful Commands

## Run Server

```bash
py manage.py runserver
```

## Create App

```bash
py manage.py startapp app_name
```

## Create Migration

```bash
py manage.py makemigrations
```

## Apply Migration

```bash
py manage.py migrate
```

## Create Superuser

```bash
py manage.py createsuperuser
```

---

# 31. Testing APIs with Postman

## GET Request

```text
GET http://127.0.0.1:8000/products/
```

---

## POST Request

```text
POST http://127.0.0.1:8000/products/
```

JSON Body:

```json
{
    "name": "Laptop",
    "price": 50000,
    "quantity": 10
}
```

---

## PUT Request

```text
PUT http://127.0.0.1:8000/products/1/
```

---

## PATCH Request

```text
PATCH http://127.0.0.1:8000/products/1/
```

---

## DELETE Request

```text
DELETE http://127.0.0.1:8000/products/1/
```

---

# 32. Final Notes

Django is used for backend development and database handling.

Django REST Framework is used to create REST APIs.

Main workflow:

```text
Model → Serializer → View → URL
```

This is the core structure of most Django REST Framework projects.

---

# 33. Quick Revision Summary

| Topic       | Purpose                   |
| ----------- | ------------------------- |
| Django      | Backend Framework         |
| DRF         | API Framework             |
| Model       | Database Table            |
| Serializer  | Convert Data to JSON      |
| View        | Handles Logic             |
| URL         | API Route                 |
| Migration   | Create Database Tables    |
| ViewSet     | Automatic CRUD Operations |
| Router      | Automatic URL Creation    |
| Status Code | API Response Status       |

---

# 34. Recommended Learning Path

1. Django Basics
2. Models
3. Admin Panel
4. APIs
5. Serializers
6. CRUD Operations
7. Generic Views
8. ViewSets
9. Authentication
10. Deployment

---

# 35. Conclusion

This guide covers the complete Django and Django REST Framework revision process from beginner level to API development. By practicing these examples, you can build real-world backend applications such as:

* Billing Systems
* POS Systems
* E-Commerce APIs
* Inventory Management Systems
* Employee Management Systems
* Authentication Systems

Keep practicing CRUD operations and API building to improve your Django skills.
