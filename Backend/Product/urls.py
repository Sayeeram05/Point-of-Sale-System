from django.urls import path
from .views import ProductList, ProductDetail, ProductByCategory

urlpatterns = [
    path('products/create/', ProductList.as_view(), name='product-create'),
    path('products/category/<int:category_id>/', ProductByCategory.as_view(), name='product-by-category'),
    path('products/<int:id>/update/', ProductList.as_view(), name='product-update'),
    path('products/<int:id>/delete/', ProductList.as_view(), name='product-delete'),
    path('products/<int:id>/', ProductDetail.as_view(), name='product-detail'),
    path('products/', ProductList.as_view(), name='product-list'),
]