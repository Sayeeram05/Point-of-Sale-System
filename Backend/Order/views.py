from datetime import datetime, time, timedelta

from django.db.models import Sum, Count
from django.db.models.functions import (
    TruncHour,
    TruncDay,
    TruncWeek,
    TruncMonth,
    TruncYear,
)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Order, OrderItem
from .serializers import OrderSerializer, OrderItemSerializer
from django.db import transaction
from Product.models import Product
from decimal import Decimal, InvalidOperation


class OrderList(APIView):
    def get(self, request, id=None):
        if id is not None:
            try:
                order = Order.objects.get(ID=id)
            except Order.DoesNotExist:
                return Response(
                    {"error": "Order not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )
            serializer = OrderSerializer(order)
            return Response(serializer.data)

        date = request.query_params.get("date")
        orders = Order.objects.filter(Completed=True)

        grouped_orders = None

        # =====================================================
        # TODAY → HOUR
        # =====================================================

        if date == "today":
            today = datetime.now().date()

            start = datetime.combine(today, time.min)
            end = start + timedelta(days=1)

            orders = orders.filter(CreatedAt__gte=start, CreatedAt__lt=end)

            grouped_orders = (
                orders.annotate(period=TruncHour("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount"),
                )
                .order_by("period")
            )

        # =====================================================
        # YESTERDAY → HOUR
        # =====================================================

        elif date == "yesterday":
            yesterday = datetime.now().date() - timedelta(days=1)

            start = datetime.combine(yesterday, time.min)
            end = start + timedelta(days=1)

            orders = orders.filter(CreatedAt__gte=start, CreatedAt__lt=end)

            grouped_orders = (
                orders.annotate(period=TruncHour("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount"),
                )
                .order_by("period")
            )

        # =====================================================
        # THIS WEEK → DAY
        # =====================================================

        elif date == "this_week":
            today = datetime.now().date()

            start_of_week = today - timedelta(days=today.weekday())

            start = datetime.combine(start_of_week, time.min)

            orders = orders.filter(CreatedAt__gte=start, CreatedAt__lt=datetime.now())

            grouped_orders = (
                orders.annotate(period=TruncDay("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount"),
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

            orders = orders.filter(CreatedAt__gte=start, CreatedAt__lt=datetime.now())

            grouped_orders = (
                orders.annotate(period=TruncWeek("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount"),
                )
                .order_by("period")
            )

        # =====================================================
        # THIS YEAR → MONTH
        # =====================================================

        elif date == "this_year":
            today = datetime.now().date()

            start_of_year = today.replace(month=1, day=1)

            start = datetime.combine(start_of_year, time.min)

            orders = orders.filter(CreatedAt__gte=start, CreatedAt__lt=datetime.now())

            grouped_orders = (
                orders.annotate(period=TruncMonth("CreatedAt"))
                .values("period")
                .annotate(
                    orders_count=Count("ID"),
                    total_upi=Sum("UpiAmount"),
                    total_cash=Sum("CashAmount"),
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
                    {"error": "start_date and end_date are required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            try:
                start_date = datetime.strptime(start_date, "%Y-%m-%d").date()

                end_date = datetime.strptime(end_date, "%Y-%m-%d").date()

            except ValueError:
                return Response(
                    {"error": "Invalid date format. Use YYYY-MM-DD"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            orders = orders.filter(
                CreatedAt__gte=datetime.combine(start_date, time.min),
                CreatedAt__lt=datetime.combine(end_date + timedelta(days=1), time.min),
            )

            days_difference = (end_date - start_date).days

            # =================================================
            # SINGLE DAY → HOUR
            # =================================================

            if days_difference == 0:
                grouped_orders = (
                    orders.annotate(period=TruncHour("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount"),
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 7 DAYS → DAY
            # =================================================

            elif days_difference <= 7:
                grouped_orders = (
                    orders.annotate(period=TruncDay("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount"),
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 30 DAYS → WEEK
            # =================================================

            elif days_difference <= 30:
                grouped_orders = (
                    orders.annotate(period=TruncWeek("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount"),
                    )
                    .order_by("period")
                )

            # =================================================
            # <= 365 DAYS → MONTH
            # =================================================

            elif days_difference <= 365:
                grouped_orders = (
                    orders.annotate(period=TruncMonth("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount"),
                    )
                    .order_by("period")
                )

            # =================================================
            # > 365 DAYS → YEAR
            # =================================================

            else:
                grouped_orders = (
                    orders.annotate(period=TruncYear("CreatedAt"))
                    .values("period")
                    .annotate(
                        orders_count=Count("ID"),
                        total_upi=Sum("UpiAmount"),
                        total_cash=Sum("CashAmount"),
                    )
                    .order_by("period")
                )

        # =====================================================
        # INVALID PARAMETER
        # =====================================================

        else:
            return Response(
                {"error": "Invalid date parameter"}, status=status.HTTP_400_BAD_REQUEST
            )

        # =====================================================
        # TOTALS AND INDIVIDUAL ORDERS
        # =====================================================

        totals = orders.aggregate(
            total_upi=Sum("UpiAmount"), total_cash=Sum("CashAmount")
        )

        total_upi = totals["total_upi"] or 0
        total_cash = totals["total_cash"] or 0

        total_amount = total_upi + total_cash

        # Get individual orders for the orders list
        individual_orders = (
            orders.select_related("ColorId", "EmojiId")
            .prefetch_related("OrderItems__ProductID")
            .order_by("-CreatedAt")[:50]
        )  # Limit to 50 most recent orders

        orders_list = []
        for order in individual_orders:
            # Get order items with product names
            items = []
            for item in order.OrderItems.all():
                data = {
                    "ProductID": item.ProductID.ID,
                    "ProductName": item.ProductID.Name,
                    "Quantity": item.Quantity,
                    "Price": float(item.PriceAtPurchase),
                }
                items.append(data)

            # Determine payment method
            payment_method = "UPI" if order.UpiAmount > order.CashAmount else "Cash"
            if order.UpiAmount > 0 and order.CashAmount > 0:
                payment_method = f"UPI ₹{order.UpiAmount} + Cash ₹{order.CashAmount}"

            orders_list.append(
                {
                    "id": f"#ORD-{order.ID}",
                    "date": order.CreatedAt.isoformat(),
                    "items": items,
                    "total_amount": float(order.UpiAmount + order.CashAmount),
                    "payment_method": payment_method,
                    "status": "Completed" if order.Completed else "Pending",
                    "customer_name": f"Customer {order.ID}",  # Since there's no customer name in the model
                }
            )

        return Response(
            {
                "summary": {
                    "orders_count": orders.count(),
                    "total_upi": total_upi,
                    "total_cash": total_cash,
                    "total_amount": total_amount,
                },
                "analytics": list(grouped_orders),
                "orders": orders_list,
            }
        )

    def post(self, request):
        serializer = OrderSerializer(data=request.data)
        if serializer.is_valid():
            order = serializer.save()

            # Build a mobile-friendly response so clients receive a usable order_id
            items = []
            item_total = Decimal("0.00")
            for item in order.OrderItems.all():
                items.append(
                    {
                        "ProductID": item.ProductID.ID,
                        "ProductName": item.ProductID.Name,
                        "Quantity": item.Quantity,
                        "PriceAtPurchase": float(item.PriceAtPurchase),
                    }
                )
                item_total += item.PriceAtPurchase * item.Quantity

            payload = {
                "order_id": order.ID,
                "id": f"#ORD-{order.ID}",
                "items": items,
                "price": str(item_total),
                "total_amount": str(item_total),
                "upi_amount": str(order.UpiAmount),
                "cash_amount": str(order.CashAmount),
                "payment_method": (
                    "UPI" if order.UpiAmount > order.CashAmount else "Cash"
                )
                if not (order.UpiAmount and order.CashAmount)
                else f"UPI {order.UpiAmount} + Cash {order.CashAmount}",
                "customer_name": f"Customer {order.ID}",
                "status": "Completed" if order.Completed else "Pending",
                "completed": bool(order.Completed),
                "order_date": order.CreatedAt.isoformat(),
                "emoji": getattr(order.EmojiId, "Emoji", None)
                if getattr(order, "EmojiId", None)
                else None,
                "color": getattr(order.ColorId, "HexCode", None)
                if getattr(order, "ColorId", None)
                else None,
            }

            return Response(payload, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response(
                {"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND
            )
        # Work with a mutable copy and accept different key casings
        data = request.data.copy()
        items = (
            data.pop("OrderItems", None)
            or data.pop("orderItems", None)
            or data.pop("order_items", None)
            or data.pop("items", None)
            or []
        )

        serializer = OrderSerializer(order, data=data, partial=True)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Persist order fields and items atomically
        try:
            # Debug log incoming payload for easier troubleshooting
            try:
                print(f"[Order PUT] id={id} payload={data}")
            except Exception:
                pass
            with transaction.atomic():
                order = serializer.save()

                # If items provided, replace existing items
                if items:
                    # Remove old items
                    OrderItem.objects.filter(OrderId=order).delete()

                    created_items = []
                    for idx, raw in enumerate(items):
                        # Normalize keys from mobile clients
                        product_pk = (
                            raw.get("ProductID")
                            or raw.get("product_id")
                            or raw.get("item_id")
                            or raw.get("itemId")
                        )
                        quantity = (
                            raw.get("Quantity")
                            or raw.get("quantity")
                            or raw.get("pieces")
                        )
                        price = (
                            raw.get("PriceAtPurchase")
                            or raw.get("price")
                            or raw.get("Price")
                        )

                        if product_pk is None or quantity is None or price is None:
                            raise ValueError(f"Missing fields for OrderItems[{idx}]")

                        try:
                            quantity = int(quantity)
                        except (TypeError, ValueError):
                            raise ValueError(f"Invalid quantity for OrderItems[{idx}]")

                        try:
                            price = Decimal(str(price))
                        except (InvalidOperation, TypeError):
                            raise ValueError(f"Invalid price for OrderItems[{idx}]")

                        # Resolve product FK
                        try:
                            product = Product.objects.get(ID=int(product_pk))
                        except Exception:
                            raise ValueError(
                                f"Product not found for OrderItems[{idx}] (ProductID={product_pk})"
                            )

                        oi = OrderItem.objects.create(
                            OrderId=order,
                            ProductID=product,
                            Quantity=quantity,
                            PriceAtPurchase=price,
                        )
                        created_items.append(oi)

                    # Debug log created items
                    try:
                        print(
                            f"[Order PUT] id={order.ID} created_items_count={len(created_items)}"
                        )
                        for ci in created_items:
                            print(
                                f"[Order PUT] Created OrderItem id={ci.ID} product={ci.ProductID.ID} qty={ci.Quantity} price={ci.PriceAtPurchase}"
                            )
                    except Exception:
                        pass

                # Refresh and return mobile-friendly order representation
                order.refresh_from_db()
                items_out = []
                item_total = Decimal("0.00")
                for item in order.OrderItems.all():
                    items_out.append(
                        {
                            "ProductID": item.ProductID.ID,
                            "ProductName": item.ProductID.Name,
                            "Quantity": item.Quantity,
                            "PriceAtPurchase": float(item.PriceAtPurchase),
                        }
                    )
                    item_total += item.PriceAtPurchase * item.Quantity

                payload = {
                    "order_id": order.ID,
                    "id": f"#ORD-{order.ID}",
                    "items": items_out,
                    "price": str(item_total),
                    "total_amount": str(item_total),
                    "upi_amount": str(order.UpiAmount),
                    "cash_amount": str(order.CashAmount),
                    "payment_method": (
                        "UPI" if order.UpiAmount > order.CashAmount else "Cash"
                    )
                    if not (order.UpiAmount and order.CashAmount)
                    else f"UPI {order.UpiAmount} + Cash {order.CashAmount}",
                    "customer_name": f"Customer {order.ID}",
                    "status": "Completed" if order.Completed else "Pending",
                    "completed": bool(order.Completed),
                    "order_date": order.CreatedAt.isoformat(),
                    "emoji": getattr(order.EmojiId, "Emoji", None)
                    if getattr(order, "EmojiId", None)
                    else None,
                    "color": getattr(order.ColorId, "HexCode", None)
                    if getattr(order, "ColorId", None)
                    else None,
                }

                return Response(payload, status=status.HTTP_200_OK)

        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response(
                {"error": "Failed to update order", "detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def patch(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response(
                {"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = OrderSerializer(order, data=request.data, partial=True)

        if serializer.is_valid():
            order = serializer.save()

            # Return mobile-friendly payload after patch
            items_out = []
            item_total = Decimal("0.00")
            for item in order.OrderItems.all():
                items_out.append(
                    {
                        "ProductID": item.ProductID.ID,
                        "ProductName": item.ProductID.Name,
                        "Quantity": item.Quantity,
                        "PriceAtPurchase": float(item.PriceAtPurchase),
                    }
                )
                item_total += item.PriceAtPurchase * item.Quantity

            payload = {
                "order_id": order.ID,
                "id": f"#ORD-{order.ID}",
                "items": items_out,
                "price": str(item_total),
                "total_amount": str(item_total),
                "upi_amount": str(order.UpiAmount),
                "cash_amount": str(order.CashAmount),
                "payment_method": (
                    "UPI" if order.UpiAmount > order.CashAmount else "Cash"
                )
                if not (order.UpiAmount and order.CashAmount)
                else f"UPI {order.UpiAmount} + Cash {order.CashAmount}",
                "customer_name": f"Customer {order.ID}",
                "status": "Completed" if order.Completed else "Pending",
                "completed": bool(order.Completed),
                "order_date": order.CreatedAt.isoformat(),
                "emoji": getattr(order.EmojiId, "Emoji", None)
                if getattr(order, "EmojiId", None)
                else None,
                "color": getattr(order.ColorId, "HexCode", None)
                if getattr(order, "ColorId", None)
                else None,
            }

            return Response(payload, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, id):
        try:
            order = Order.objects.get(ID=id)
        except Order.DoesNotExist:
            return Response(
                {"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND
            )

        order.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class OrdersListToday(OrderList):
    def get(self, request):

        # =====================================================
        # TODAY → HOUR
        # =====================================================

        today = datetime.now().date()

        start = datetime.combine(today, time.min)
        end = start + timedelta(days=1)

        Allorders = Order.objects.filter(CreatedAt__gte=start, CreatedAt__lt=end)

        # =====================================================
        # TOTALS AND INDIVIDUAL ORDERS
        # =====================================================

        TodaysOrders = Allorders.count()

        completedorders = Allorders.filter(Completed=True)

        totals = completedorders.aggregate(
            total_upi=Sum("UpiAmount"), total_cash=Sum("CashAmount")
        )

        total_upi = totals["total_upi"] or 0
        total_cash = totals["total_cash"] or 0

        total_amount = total_upi + total_cash

        print(Allorders, completedorders)

        # Get individual orders for the orders list
        individual_orders = (
            Allorders.select_related("ColorId", "EmojiId")
            .prefetch_related("OrderItems__ProductID")
            .order_by("-CreatedAt")
        )  # Limit to 50 most recent orders
        print(individual_orders)
        orders_list = []
        for order in individual_orders:
            # Get order items with product names
            items = []
            item_total = Decimal("0.00")
            for item in order.OrderItems.all():
                data = {
                    "ProductID": item.ProductID.ID,
                    "ProductName": item.ProductID.Name,
                    "Quantity": item.Quantity,
                    "Price": float(item.PriceAtPurchase),
                }
                items.append(data)
                item_total += item.PriceAtPurchase * item.Quantity

            # Determine payment method
            payment_method = "UPI" if order.UpiAmount > order.CashAmount else "Cash"
            if order.UpiAmount > 0 and order.CashAmount > 0:
                payment_method = f"UPI ₹{order.UpiAmount} + Cash ₹{order.CashAmount}"

            orders_list.append(
                {
                    "id": f"{order.ID}",
                    "order_id": order.ID,
                    "date": order.CreatedAt.isoformat(),
                    "items": items,
                    "price": float(item_total),
                    "total_amount": float(item_total),
                    "upi_amount": float(order.UpiAmount),
                    "cash_amount": float(order.CashAmount),
                    "payment_method": payment_method,
                    "status": "Completed" if order.Completed else "Pending",
                    "customer_name": f"Customer {order.ID}",
                }
            )

        return Response(
            {
                "summary": {
                    "orders_count": TodaysOrders,
                    "total_upi": total_upi,
                    "total_cash": total_cash,
                    "total_amount": total_amount,
                },
                "orders": orders_list,
            }
        )
