"""
ASGI config for Main project.

Supports both HTTP (Django REST) and WebSocket (Django Channels) protocols.
"""

import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Main.settings')

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import Order.routing

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(Order.routing.websocket_urlpatterns)
    ),
})
