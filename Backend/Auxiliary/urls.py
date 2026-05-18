from django.urls import path
from . import views

urlpatterns = [
    path('color/', views.ColorView.as_view(), name='color-list'),
    path('color/create/', views.ColorView.as_view(), name='color-create'),
    path('color/<int:id>/update/', views.ColorView.as_view(), name='color-update'),
    path('color/<int:id>/delete/', views.ColorView.as_view(), name='color-delete'),
    path('emoji/', views.EmojiView.as_view(), name='emoji-list'),
    path('emoji/create/', views.EmojiView.as_view(), name='emoji-create'),
    path('emoji/<int:id>/update/', views.EmojiView.as_view(), name='emoji-update'),
    path('emoji/<int:id>/delete/', views.EmojiView.as_view(), name='emoji-delete'),
]