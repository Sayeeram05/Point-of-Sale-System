from django.urls import path
from .views import OrderList

urlpatterns = [
    path('orders/create/', OrderList.as_view(), name='order-create'),
    path('orders/<int:id>/update/', OrderList.as_view(), name='order-update'),
    path('orders/<int:id>/patch/', OrderList.as_view(), name='order-patch'),
    path('orders/<int:id>/delete/', OrderList.as_view(), name='order-delete'),
    path('orders/', OrderList.as_view(), name='order-list'),
]