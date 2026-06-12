from django.apps import AppConfig


class OrderConfig(AppConfig):
    name = 'Order'

    def ready(self):
        import Order.signals  # noqa: F401
