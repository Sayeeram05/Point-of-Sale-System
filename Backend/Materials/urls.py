from django.urls import path
from .views import RawMaterialListView, RawMaterialDetailView, PurchaseRecordView

urlpatterns = [
    # Raw material catalog endpoints
    path('materials/', RawMaterialListView.as_view(), name='raw-materials-list'),
    path('materials/<int:pk>/', RawMaterialDetailView.as_view(), name='raw-material-detail'),

    # Purchase record endpoints
    path('materials/purchases/', PurchaseRecordView.as_view(), name='purchase-records'),
]
