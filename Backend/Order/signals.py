from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from asgiref.sync import async_to_sync

from .models import Order
from .consumers import OrderConsumer


@receiver(post_save, sender=Order)
def order_saved(sender, instance, created, **kwargs):
    async_to_sync(OrderConsumer.broadcast)(
        "created" if created else "updated",
        instance.ID,
    )


@receiver(post_delete, sender=Order)
def order_deleted(sender, instance, **kwargs):
    async_to_sync(OrderConsumer.broadcast)("deleted", instance.ID)
