from datetime import date
from decimal import Decimal, InvalidOperation

from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import RawMaterial, PurchaseRecord, PurchaseItem
from .serializers import (
    RawMaterialSerializer,
    PurchaseRecordSerializer,
    PurchaseSaveSerializer,
)


class RawMaterialListView(APIView):
    """
    GET  /api/materials/        — List all active raw materials.
    POST /api/materials/        — Create a new raw material.
    """

    def get(self, request):
        materials = RawMaterial.objects.filter(is_active=True)
        return Response(RawMaterialSerializer(materials, many=True).data)

    def post(self, request):
        serializer = RawMaterialSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RawMaterialDetailView(APIView):
    """
    GET    /api/materials/<pk>/  — Retrieve a single raw material.
    PUT    /api/materials/<pk>/  — Full or partial update of a raw material.
    DELETE /api/materials/<pk>/  — Soft-delete (sets is_active=False).
    """

    def get(self, request, pk):
        material = get_object_or_404(RawMaterial, pk=pk)
        return Response(RawMaterialSerializer(material).data)

    def put(self, request, pk):
        material = get_object_or_404(RawMaterial, pk=pk)
        serializer = RawMaterialSerializer(material, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        material = get_object_or_404(RawMaterial, pk=pk)
        material.is_active = False
        material.save(update_fields=['is_active', 'updated_at'])
        return Response({'message': 'Material deactivated successfully.'}, status=status.HTTP_200_OK)


class PurchaseRecordView(APIView):
    """
    GET   /api/materials/purchases/?date=YYYY-MM-DD
          → Returns the full record for that date (items + lock state).
          → 404 if no record exists yet.

    GET   /api/materials/purchases/   (no date param)
          → Returns a summary of the last 7 days (available dates list).

    POST  /api/materials/purchases/
          → Atomically creates or fully replaces the record for target_date.
          → Always locks the record (is_locked=True) on successful save.
          → Returns 201 on first creation, 200 on update.

    PATCH /api/materials/purchases/
          → Toggles is_locked for an existing record.
          → Body: { "date": "YYYY-MM-DD", "is_locked": true/false }
    """

    def get(self, request):
        date_param = request.query_params.get('date')

        if not date_param:
            # Return the last 15 actual purchase entry dates (ordered newest first)
            records = PurchaseRecord.objects.order_by('-target_date')[:15]
            serializer = PurchaseRecordSerializer(records, many=True)
            return Response({
                'records': serializer.data,
                'available_dates': [r.target_date.isoformat() for r in records],
            })

        try:
            record = PurchaseRecord.objects.get(target_date=date_param)
            return Response(PurchaseRecordSerializer(record).data)
        except PurchaseRecord.DoesNotExist:
            return Response(
                {'detail': 'No purchase record found for this date.', 'target_date': date_param},
                status=status.HTTP_404_NOT_FOUND,
            )

    @transaction.atomic
    def post(self, request):
        serializer = PurchaseSaveSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        target_date = data['target_date']
        notes = data.get('notes', '')
        items_data = data['items']

        # Create or replace the record header
        record, created = PurchaseRecord.objects.update_or_create(
            target_date=target_date,
            defaults={'notes': notes, 'is_locked': True},
        )

        # Wipe existing items and re-insert (clean-slate approach ensures consistency)
        record.items.all().delete()

        total_cost = Decimal('0.00')
        for item_data in items_data:
            try:
                price = Decimal(str(item_data['base_price_snapshot']))
                qty = Decimal(str(item_data['quantity']))
                subtotal = price * qty
                total_cost += subtotal
            except (InvalidOperation, KeyError) as exc:
                return Response(
                    {'detail': f'Invalid numeric value in item payload: {exc}'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Resolve optional FK to master material
            raw_material = None
            if item_data.get('raw_material_id'):
                try:
                    raw_material = RawMaterial.objects.get(pk=item_data['raw_material_id'])
                except RawMaterial.DoesNotExist:
                    pass

            PurchaseItem.objects.create(
                record=record,
                raw_material=raw_material,
                material_name=item_data['material_name'],
                base_price_snapshot=price,
                quantity=qty,
                subtotal=subtotal,
            )

        record.total_cost = total_cost
        record.save(update_fields=['total_cost', 'notes', 'is_locked', 'updated_at'])

        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(PurchaseRecordSerializer(record).data, status=response_status)

    @transaction.atomic
    def patch(self, request):
        date_str = request.data.get('date')
        is_locked = request.data.get('is_locked')

        if date_str is None or is_locked is None:
            return Response(
                {'detail': "Both 'date' and 'is_locked' fields are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            record = PurchaseRecord.objects.get(target_date=date_str)
        except PurchaseRecord.DoesNotExist:
            return Response(
                {'detail': 'No purchase record found for this date.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        record.is_locked = bool(is_locked)
        record.save(update_fields=['is_locked', 'updated_at'])
        return Response(PurchaseRecordSerializer(record).data)
