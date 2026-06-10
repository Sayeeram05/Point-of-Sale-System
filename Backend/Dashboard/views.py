from datetime import datetime, time, timedelta
from decimal import Decimal

from django.conf import settings
from django.db.models import Sum, Count, F
from django.db.models.functions import (
    Coalesce,
    TruncHour,
    TruncDay,
    TruncWeek,
    TruncMonth,
    TruncYear,
)
from django.utils import timezone
from rest_framework.response import Response
from rest_framework.views import APIView

from Order.models import Order, OrderItem


class DashboardView(APIView):
    """Main dashboard endpoint. Returns summary and chart data from Order and OrderItem."""

    ALLOWED_RANGES = {
        "today",
        "yesterday",
        "this_week",
        "this_month",
        "this_year",
        "custom",
        "week",
    }

    def get(self, request, Range="week"):
        range_key = request.query_params.get("filter", Range) or Range
        if range_key not in self.ALLOWED_RANGES:
            return Response({"error": "Invalid range parameter"}, status=400)

        try:
            start_date, end_date = self._get_date_range(range_key, request)
        except ValueError as exc:
            return Response({"error": str(exc)}, status=400)

        sales_data = self._get_sales_metrics(start_date, end_date)
        last_start_date, last_end_date = self._get_previous_range(
            range_key, start_date, end_date
        )
        last_sales_data = self._get_sales_metrics(last_start_date, last_end_date)
        top_products = self._get_top_products(start_date, end_date)
        stock_summary = self._get_stock_summary(start_date, end_date)
        recent_orders = self._get_recent_orders(5)

        grouping = self._get_grouping(range_key, start_date, end_date)
        daily_data = []
        weekly_data = []
        monthly_data = []
        yearly_data = []

        if grouping == "hour":
            daily_data = self._get_hourly_breakdown(start_date, end_date)
        elif grouping == "day":
            daily_data = self._get_daily_breakdown(start_date, end_date)
        elif grouping == "week":
            weekly_data = self._get_weekly_breakdown(start_date, end_date)
        elif grouping == "month":
            monthly_data = self._get_monthly_breakdown(start_date, end_date)
        else:
            yearly_data = self._get_yearly_breakdown(start_date, end_date)

        avg_val = (
            round(sales_data["total_revenue"] / sales_data["total_orders"], 2)
            if sales_data["total_orders"] > 0
            else 0
        )

        context = {
            "range": range_key,
            "grouping": grouping,
            "start_date": str(start_date),
            "end_date": str(end_date),
            "sales": {
                "total_orders": sales_data["total_orders"],
                "total_revenue": str(sales_data["total_revenue"]),
                "upi_revenue": str(sales_data["upi_revenue"]),
                "cash_revenue": str(sales_data["cash_revenue"]),
                "completed_orders": sales_data["completed_orders"],
                "pending_orders": sales_data["pending_orders"],
                "avg_order_value": str(avg_val),
            },
            "comparison": {
                "last_start_date": str(last_start_date),
                "last_end_date": str(last_end_date),
                "total_orders": last_sales_data["total_orders"],
                "total_revenue": str(last_sales_data["total_revenue"]),
                "upi_revenue": str(last_sales_data["upi_revenue"]),
                "cash_revenue": str(last_sales_data["cash_revenue"]),
                "order_change_pct": self._calc_pct_change(
                    last_sales_data["total_orders"], sales_data["total_orders"]
                ),
                "revenue_change_pct": self._calc_pct_change(
                    float(last_sales_data["total_revenue"]),
                    float(sales_data["total_revenue"]),
                ),
            },
            "top_products": top_products,
            "stock_summary": stock_summary,
            "daily_breakdown": daily_data,
            "weekly_breakdown": weekly_data,
            "monthly_breakdown": monthly_data,
            "yearly_breakdown": yearly_data,
            "recent_orders": recent_orders,
            "b2b_summary": {},
        }
        return Response(context, status=200)

    def _get_date_range(self, range_key, request):
        today = timezone.now().date()

        if range_key == "today":
            return today, today

        if range_key == "yesterday":
            yesterday = today - timedelta(days=1)
            return yesterday, yesterday

        if range_key in {"this_week", "week"}:
            start = today - timedelta(days=today.weekday())
            end = start + timedelta(days=6)
            return start, end

        if range_key == "this_month":
            start = today.replace(day=1)
            next_month = (start + timedelta(days=32)).replace(day=1)
            return start, next_month - timedelta(days=1)

        if range_key == "this_year":
            start = today.replace(month=1, day=1)
            end = today.replace(month=12, day=31)
            return start, end

        if range_key == "custom":
            start_str = request.query_params.get("start") or request.query_params.get(
                "start_date"
            )
            end_str = request.query_params.get("end") or request.query_params.get(
                "end_date"
            )
            if not start_str or not end_str:
                raise ValueError("start_date and end_date are required")
            try:
                start_date = datetime.strptime(start_str, "%Y-%m-%d").date()
                end_date = datetime.strptime(end_str, "%Y-%m-%d").date()
            except ValueError:
                raise ValueError("Invalid date format. Use YYYY-MM-DD")
            if end_date < start_date:
                raise ValueError("end_date must be after or equal to start_date")
            return start_date, end_date

        raise ValueError("Invalid range parameter")

    def _get_previous_range(self, range_key, start_date, end_date):
        if range_key == "today":
            previous = start_date - timedelta(days=1)
            return previous, previous

        if range_key == "yesterday":
            previous = start_date - timedelta(days=1)
            return previous, previous

        if range_key in {"this_week", "week"}:
            previous_start = start_date - timedelta(days=7)
            return previous_start, previous_start + timedelta(days=6)

        if range_key == "this_month":
            previous_end = start_date - timedelta(days=1)
            previous_start = previous_end.replace(day=1)
            return previous_start, previous_end

        if range_key == "this_year":
            previous_start = start_date.replace(year=start_date.year - 1)
            previous_end = end_date.replace(year=end_date.year - 1)
            return previous_start, previous_end

        total_days = (end_date - start_date).days + 1
        previous_end = start_date - timedelta(days=1)
        return previous_end - timedelta(days=total_days - 1), previous_end

    def _get_range_datetimes(self, start_date, end_date):
        start_dt = datetime.combine(start_date, time.min)
        end_dt = datetime.combine(end_date, time.max)
        if settings.USE_TZ:
            start_dt = timezone.make_aware(start_dt)
            end_dt = timezone.make_aware(end_dt)
        return start_dt, end_dt

    def _get_sales_metrics(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        orders = Order.objects.filter(CreatedAt__gte=start_dt, CreatedAt__lt=end_dt)
        completed = orders.filter(Completed=True)
        totals = completed.aggregate(
            cash_revenue=Coalesce(Sum("CashAmount"), Decimal("0")),
            upi_revenue=Coalesce(Sum("UpiAmount"), Decimal("0")),
            completed_orders=Count("ID"),
        )
        total_orders = orders.count()
        return {
            "total_orders": total_orders,
            "completed_orders": totals["completed_orders"],
            "pending_orders": total_orders - totals["completed_orders"],
            "cash_revenue": totals["cash_revenue"],
            "upi_revenue": totals["upi_revenue"],
            "total_revenue": totals["cash_revenue"] + totals["upi_revenue"],
        }

    def _get_top_products(self, start_date, end_date, limit=5):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        items = (
            OrderItem.objects.filter(
                OrderId__CreatedAt__gte=start_dt,
                OrderId__CreatedAt__lt=end_dt,
                OrderId__Completed=True,
            )
            .select_related("ProductID")
            .values(
                "ProductID",
                "ProductID__Name",
                "ProductID__Price",
                "ProductID__ProductCategory__Name",
            )
            .annotate(
                total_sold=Sum("Quantity"),
                revenue=Sum(F("Quantity") * F("PriceAtPurchase")),
            )
            .order_by("-total_sold")[:limit]
        )

        return [
            {
                "name": item["ProductID__Name"] or "Unknown Product",
                "price": str(item["ProductID__Price"] or Decimal("0")),
                "category": item["ProductID__ProductCategory__Name"] or "Uncategorized",
                "product_type": "product",
                "total_sold": item["total_sold"] or 0,
                "revenue": str(item["revenue"] or Decimal("0")),
            }
            for item in items
        ]

    def _get_stock_summary(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        completed_orders = Order.objects.filter(
            CreatedAt__gte=start_dt,
            CreatedAt__lt=end_dt,
            Completed=True,
        )
        total_quantity = completed_orders.aggregate(
            total_quantity=Coalesce(Sum("TotalQuantity"), 0)
        )["total_quantity"]
        item_summary = OrderItem.objects.filter(
            OrderId__CreatedAt__gte=start_dt,
            OrderId__CreatedAt__lt=end_dt,
            OrderId__Completed=True,
        ).aggregate(
            total_items=Coalesce(Sum("Quantity"), 0),
            distinct_products=Count("ProductID", distinct=True),
        )

        return {
            "total_completed_orders": completed_orders.count(),
            "total_quantity_sold": total_quantity,
            "total_items_sold": item_summary["total_items"],
            "distinct_products_sold": item_summary["distinct_products"],
        }

    def _get_hourly_breakdown(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        grouped = (
            Order.objects.filter(
                CreatedAt__gte=start_dt,
                CreatedAt__lt=end_dt,
                Completed=True,
            )
            .annotate(period=TruncHour("CreatedAt"))
            .values("period")
            .annotate(
                value=Coalesce(Sum(F("CashAmount") + F("UpiAmount")), Decimal("0"))
            )
            .order_by("period")
        )
        return [
            {"label": row["period"].strftime("%H:00"), "value": float(row["value"])}
            for row in grouped
        ]

    def _get_daily_breakdown(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        grouped = (
            Order.objects.filter(
                CreatedAt__gte=start_dt,
                CreatedAt__lt=end_dt,
                Completed=True,
            )
            .annotate(period=TruncDay("CreatedAt"))
            .values("period")
            .annotate(
                value=Coalesce(Sum(F("CashAmount") + F("UpiAmount")), Decimal("0"))
            )
            .order_by("period")
        )
        return [
            {"label": row["period"].strftime("%a"), "value": float(row["value"])}
            for row in grouped
        ]

    def _get_weekly_breakdown(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        grouped = (
            Order.objects.filter(
                CreatedAt__gte=start_dt,
                CreatedAt__lt=end_dt,
                Completed=True,
            )
            .annotate(period=TruncWeek("CreatedAt"))
            .values("period")
            .annotate(
                value=Coalesce(Sum(F("CashAmount") + F("UpiAmount")), Decimal("0"))
            )
            .order_by("period")
        )
        return [
            {"label": f"Week {index + 1}", "value": float(row["value"])}
            for index, row in enumerate(grouped)
        ]

    def _get_monthly_breakdown(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        grouped = (
            Order.objects.filter(
                CreatedAt__gte=start_dt,
                CreatedAt__lt=end_dt,
                Completed=True,
            )
            .annotate(period=TruncMonth("CreatedAt"))
            .values("period")
            .annotate(
                value=Coalesce(Sum(F("CashAmount") + F("UpiAmount")), Decimal("0"))
            )
            .order_by("period")
        )
        return [
            {"label": row["period"].strftime("%b"), "value": float(row["value"])}
            for row in grouped
        ]

    def _get_yearly_breakdown(self, start_date, end_date):
        start_dt, end_dt = self._get_range_datetimes(start_date, end_date)
        grouped = (
            Order.objects.filter(
                CreatedAt__gte=start_dt,
                CreatedAt__lt=end_dt,
                Completed=True,
            )
            .annotate(period=TruncYear("CreatedAt"))
            .values("period")
            .annotate(
                value=Coalesce(Sum(F("CashAmount") + F("UpiAmount")), Decimal("0"))
            )
            .order_by("period")
        )
        return [
            {"label": str(row["period"].year), "value": float(row["value"])}
            for row in grouped
        ]

    def _get_grouping(self, range_key, start_date, end_date):
        if range_key in {"today", "yesterday"}:
            return "hour"
        if range_key in {"this_week", "week"}:
            return "day"
        if range_key == "this_month":
            return "week"
        if range_key == "this_year":
            return "month"
        date_count = (end_date - start_date).days + 1
        if date_count <= 3:
            return "hour"
        if date_count <= 31:
            return "day"
        if date_count <= 180:
            return "week"
        return "month"

    def _get_recent_orders(self, limit=5):
        orders = (
            Order.objects.select_related("ColorId", "EmojiId")
            .annotate(items_count=Count("OrderItems"))
            .order_by("-CreatedAt")[:limit]
        )
        recent = []
        for order in orders:
            created_at = order.CreatedAt
            if timezone.is_naive(created_at):
                created_at = timezone.make_aware(
                    created_at, timezone.get_current_timezone()
                )
            order_date = timezone.localtime(created_at).strftime("%Y-%m-%d %H:%M")

            recent.append(
                {
                    "order_id": order.ID,
                    "total_price": str(order.CashAmount + order.UpiAmount),
                    "completed": order.Completed,
                    "order_date": order_date,
                    "items_count": order.items_count,
                    "emoji": getattr(order.EmojiId, "Emoji", "??"),
                    "color": getattr(order.ColorId, "HexCode", "#2196F3"),
                }
            )
        return recent

    def _calc_pct_change(self, old_val, new_val):
        if old_val == 0:
            return 100.0 if new_val > 0 else 0.0
        return round(((new_val - old_val) / old_val) * 100, 1)
