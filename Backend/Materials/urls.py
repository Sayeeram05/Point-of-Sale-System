from django.urls import path
from .views import (
    MaterialVersionList, MaterialVersionForDate, MaterialVersionItems,
    AvailableMaterials, MaterialEntryList, MaterialEntryTotal
)

urlpatterns = [
    # New Material Version APIs
    path('material-versions/', MaterialVersionList.as_view(), name='material-version-list'),
    path('material-versions/<int:id>/', MaterialVersionList.as_view(), name='material-version-detail'),
    path('material-versions/for-date/', MaterialVersionForDate.as_view(), name='material-version-for-date'),
    path('material-versions/<int:version_id>/items/', MaterialVersionItems.as_view(), name='material-version-items'),
    path('materials/available/', AvailableMaterials.as_view(), name='available-materials'),
    
    # Legacy Material entries CRUD (for backward compatibility)
    path('materials/', MaterialEntryList.as_view(), name='material-list'),
    path('materials/<int:id>/', MaterialEntryList.as_view(), name='material-detail'),
    path('materials/<int:id>/update/', MaterialEntryList.as_view(), name='material-update'),
    path('materials/<int:id>/delete/', MaterialEntryList.as_view(), name='material-delete'),
    
    # Legacy Total endpoint (for backward compatibility)
    path('materials/total/', MaterialEntryTotal.as_view(), name='material-total'),
]
