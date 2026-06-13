import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.layers import get_channel_layer

ORDERS_GROUP = "orders"


class OrderConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add(ORDERS_GROUP, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(ORDERS_GROUP, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None):
        pass

    async def order_update(self, event):
        await self.send(text_data=json.dumps({
            "type": "order_update",
            "action": event["action"],
            "order_id": event["order_id"],
        }))

    @staticmethod
    async def broadcast(action: str, order_id: int):
        layer = get_channel_layer()
        await layer.group_send(
            ORDERS_GROUP,
            {
                "type": "order_update",
                "action": action,
                "order_id": order_id,
            },
        )
