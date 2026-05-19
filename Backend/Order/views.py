from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Order,OrderItem
from .serializers import OrderSerializer, OrderItemSerializer


class OrderList(APIView):
    def get(self, request):
        orders = Order.objects.all()
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = OrderSerializer(data=request.data)
        if serializer.is_valid():
            order = serializer.save()
            return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response(
                {"error": "Order not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        items = request.data.pop("OrderItems", [])

        serializer = OrderSerializer(order, data=request.data, partial=True)

        if serializer.is_valid():
            order = serializer.save()

            # Delete old items
            OrderItem.objects.filter(OrderId=id).delete()

            # Create new items
            for item_data in items:
                item_data["OrderId"] = order.ID

                item_serializer = OrderItemSerializer(data=item_data)

                if item_serializer.is_valid():
                    item_serializer.save()
                else:
                    return Response(
                        item_serializer.errors,
                        status=status.HTTP_400_BAD_REQUEST
                    )

            return Response(
                OrderSerializer(order).data,
                status=status.HTTP_200_OK
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    def patch(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response(
                {"error": "Order not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = OrderSerializer(
            order,
            data=request.data,
            partial=True
        )

        if serializer.is_valid():
            order = serializer.save()

            return Response(
                OrderSerializer(order).data,
                status=status.HTTP_200_OK
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )
    
    def delete(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response({"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND)

        order.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)






