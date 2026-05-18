from django.urls import path
from . import views

urlpatterns = [
    path('category/', views.CategoryView.as_view(), name='category-list'),
    path('category/create/', views.CategoryView.as_view(), name='category-create'),
    path('category/<int:id>/update/', views.CategoryView.as_view(), name='category-update'),
    path('category/<int:id>/delete/', views.CategoryView.as_view(), name='category-delete'),
]