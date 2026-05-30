from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.DashboardView.as_view(), name='dashboard-default'),
    path('dashboard/<str:Range>/', views.DashboardView.as_view(), name='dashboard'),
]