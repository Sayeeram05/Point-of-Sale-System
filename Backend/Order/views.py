from datetime import datetime, time, timedelta

from django.db.models import Sum, Count
from django.db.models.functions import (
    TruncHour,
    TruncDay,
    TruncWeek,
    TruncMonth,
    TruncYear
)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Order, OrderItem
from .serializers import OrderSerializer, OrderItemSerializer


class OrderList(APIView):


    def get(self, request):

        date = request.query_params.get("date")

        orders = Order.objects.filter(
            Completed=True
        )

        grouped_orders = None

        # =====================================================
        # TODAY → HOUR
        # =====================================================

        if date == "today":

            today = datetime.now().date()

            start = datetime.combine(today, time.min)
            end = start + timedelta(days=1)

            orders = orders.filter(
                CreatedAt__gte=start,
                CreatedAt__lt=end
            )

            grouped_orders = (
                orders
                .annotate(period=TruncHour("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount")
                )
                .order_by("period")
            )

        # =====================================================
        # YESTERDAY → HOUR
        # =====================================================

        elif date == "yesterday":

            yesterday = (
                datetime.now().date()
                - timedelta(days=1)
            )

            start = datetime.combine(yesterday, time.min)
            end = start + timedelta(days=1)

            orders = orders.filter(
                CreatedAt__gte=start,
                CreatedAt__lt=end
            )

            grouped_orders = (
                orders
                .annotate(period=TruncHour("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount")
                )
                .order_by("period")
            )

        # =====================================================
        # THIS WEEK → DAY
        # =====================================================

        elif date == "this_week":

            today = datetime.now().date()

            start_of_week = (
                today - timedelta(days=today.weekday())
            )

            start = datetime.combine(start_of_week, time.min)

            orders = orders.filter(
                CreatedAt__gte=start,
                CreatedAt__lt=datetime.now()
            )

            grouped_orders = (
                orders
                .annotate(period=TruncDay("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount")
                )
                .order_by("period")
            )

        # =====================================================
        # THIS MONTH → WEEK
        # =====================================================

        elif date == "this_month":

            today = datetime.now().date()

            start_of_month = today.replace(day=1)

            start = datetime.combine(start_of_month, time.min)

            orders = orders.filter(
                CreatedAt__gte=start,
                CreatedAt__lt=datetime.now()
            )

            grouped_orders = (
                orders
                .annotate(period=TruncWeek("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount")
                )
                .order_by("period")
            )

        # =====================================================
        # THIS YEAR → MONTH
        # =====================================================

        elif date == "this_year":

            today = datetime.now().date()

            start_of_year = today.replace(
                month=1,
                day=1
            )

            start = datetime.combine(start_of_year, time.min)

            orders = orders.filter(
                CreatedAt__gte=start,
                CreatedAt__lt=datetime.now()
            )

            grouped_orders = (
                orders
                .annotate(period=TruncMonth("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount")
                )
                .order_by("period")
            )

        # =====================================================
        # CUSTOM
        # =====================================================

        elif date == "custom":

            start_date = request.query_params.get("start_date")
            end_date = request.query_params.get("end_date")

            if not start_date or not end_date:

                return Response(
                    {
                        "error":
                        "start_date and end_date are required"
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            try:

                start_date = datetime.strptime(
                    start_date,
                    "%Y-%m-%d"
                ).date()

                end_date = datetime.strptime(
                    end_date,
                    "%Y-%m-%d"
                ).date()

            except ValueError:

                return Response(
                    {
                        "error":
                        "Invalid date format. Use YYYY-MM-DD"
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            orders = orders.filter(
                CreatedAt__gte=datetime.combine(
                    start_date,
                    time.min
                ),
                CreatedAt__lt=datetime.combine(
                    end_date + timedelta(days=1),
                    time.min
                )
            )

            days_difference = (
                end_date - start_date
            ).days

            # =================================================
            # SINGLE DAY → HOUR
            # =================================================

            if days_difference == 0:

                grouped_orders = (
                    orders
                    .annotate(period=TruncHour("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount")
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 7 DAYS → DAY
            # =================================================

            elif days_difference <= 7:

                grouped_orders = (
                    orders
                    .annotate(period=TruncDay("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount")
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 30 DAYS → WEEK
            # =================================================

            elif days_difference <= 30:

                grouped_orders = (
                    orders
                    .annotate(period=TruncWeek("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount")
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 365 DAYS → MONTH
            # =================================================

            elif days_difference <= 365:

                grouped_orders = (
                    orders
                    .annotate(period=TruncMonth("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount")
                    )
                    .order_by("period")
                )

            # =================================================
            # > 365 DAYS → YEAR
            # =================================================

            else:

                grouped_orders = (
                    orders
                    .annotate(period=TruncYear("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount")
                    )
                    .order_by("period")
                )

        # =====================================================
        # INVALID PARAMETER
        # =====================================================

        else:

            return Response(
                {
                    "error": "Invalid date parameter"
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # =====================================================
        # TOTALS AND INDIVIDUAL ORDERS
        # =====================================================

        totals = orders.aggregate(
            total_upi=Sum("UpiAmount"),
            total_cash=Sum("CashAmount")
        )

        total_upi = totals["total_upi"] or 0
        total_cash = totals["total_cash"] or 0

        total_amount = total_upi + total_cash

        # Get individual orders for the orders list
        individual_orders = orders.select_related('ColorId', 'EmojiId').prefetch_related('OrderItems__ProductID').order_by('-CreatedAt')[:50]  # Limit to 50 most recent orders
        
        orders_list = []
        for order in individual_orders:
            # Get order items with product names
            items = []
            for item in order.OrderItems.all():
                items.append(f"{item.ProductID.Name} ({item.Quantity})")
            
            # Determine payment method
            payment_method = 'UPI' if order.UpiAmount > order.CashAmount else 'Cash'
            if order.UpiAmount > 0 and order.CashAmount > 0:
                payment_method = f'UPI ₹{order.UpiAmount} + Cash ₹{order.CashAmount}'
            
            orders_list.append({
                'id': f'#ORD-{order.ID}',
                'date': order.CreatedAt.isoformat(),
                'items': items,
                'total_amount': float(order.UpiAmount + order.CashAmount),
                'payment_method': payment_method,
                'status': 'Completed' if order.Completed else 'Pending',
                'customer_name': f'Customer {order.ID}',  # Since there's no customer name in the model
            })

        return Response({

            "summary": {
                "orders_count": orders.count(),
                "total_upi": total_upi,
                "total_cash": total_cash,
                "total_amount": total_amount
            },

            "analytics": list(grouped_orders),
            
            "orders": orders_list

        })

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






