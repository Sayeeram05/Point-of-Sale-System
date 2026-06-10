from rest_framework import serializers
from .models import RawMaterial, PurchaseRecord, PurchaseItem


class RawMaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = RawMaterial
        fields = ['id', 'name', 'unit', 'base_price', 'is_active', 'created_at', 'updated_at']


class PurchaseItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PurchaseItem
        fields = ['id', 'raw_material', 'material_name', 'base_price_snapshot', 'quantity', 'subtotal']
        read_only_fields = ['subtotal']


class PurchaseRecordSerializer(serializers.ModelSerializer):
    items = PurchaseItemSerializer(many=True, read_only=True)

    class Meta:
        model = PurchaseRecord
        fields = [
            'id', 'target_date', 'total_cost', 'is_locked',
            'notes', 'items', 'created_at', 'updated_at',
        ]


class PurchaseSaveSerializer(serializers.Serializer):
    """Validates the POST body for creating/replacing a purchase record."""
    target_date = serializers.DateField()
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    items = serializers.ListField(
        child=serializers.DictField(),
        allow_empty=True,
    )

    def validate_items(self, items):
        for item in items:
            if not item.get('material_name', '').strip():
                raise serializers.ValidationError("Each item must have a non-empty 'material_name'.")
            if 'base_price_snapshot' not in item:
                raise serializers.ValidationError("Each item must include 'base_price_snapshot'.")
            if 'quantity' not in item:
                raise serializers.ValidationError("Each item must include 'quantity'.")
        return items
