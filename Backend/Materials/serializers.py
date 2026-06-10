from rest_framework import serializers
from .models import MaterialVersion, MaterialVersionItem, MaterialEntry


class MaterialVersionItemSerializer(serializers.ModelSerializer):
    """
    Serializer for MaterialVersionItem model.
    """
    class Meta:
        model = MaterialVersionItem
        fields = ['id', 'material_name', 'price', 'quantity', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_price(self, value):
        """
        Ensure price is non-negative.
        """
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        return value

    def validate_material_name(self, value):
        """
        Ensure material_name is not empty.
        """
        if not value or not value.strip():
            raise serializers.ValidationError("Material name is required.")
        return value.strip()


class MaterialVersionSerializer(serializers.ModelSerializer):
    """
    Serializer for MaterialVersion model.
    """
    material_items = MaterialVersionItemSerializer(many=True, read_only=True)
    total_cost = serializers.SerializerMethodField()
    items_count = serializers.SerializerMethodField()

    class Meta:
        model = MaterialVersion
        fields = [
            'id', 'name', 'effective_from_date', 'is_active', 
            'material_items', 'total_cost', 'items_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_total_cost(self, obj):
        """Calculate total cost of all materials in this version"""
        return sum(item.price * item.quantity for item in obj.material_items.all())

    def get_items_count(self, obj):
        """Get count of materials in this version"""
        return obj.material_items.count()

    def validate_effective_from_date(self, value):
        """
        Ensure effective_from_date is not in the past for new versions.
        """
        if self.instance is None and value < serializers.DateField().to_internal_value('today'):
            raise serializers.ValidationError("Effective date cannot be in the past for new versions.")
        return value


class MaterialVersionCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new material versions with items.
    """
    material_items = MaterialVersionItemSerializer(many=True, required=False)

    class Meta:
        model = MaterialVersion
        fields = ['name', 'effective_from_date', 'material_items']

    def create(self, validated_data):
        """
        Create a new material version with its items.
        """
        material_items_data = validated_data.pop('material_items', [])
        
        # Create the version
        version = MaterialVersion.objects.create(**validated_data)
        
        # Create material items
        for item_data in material_items_data:
            MaterialVersionItem.objects.create(version=version, **item_data)
        
        return version


class MaterialVersionUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating existing material versions.
    """
    material_items = MaterialVersionItemSerializer(many=True, required=False)

    class Meta:
        model = MaterialVersion
        fields = ['name', 'is_active', 'material_items']

    def update(self, instance, validated_data):
        """
        Update material version and its items.
        """
        material_items_data = validated_data.pop('material_items', None)
        
        # Update version fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update material items if provided
        if material_items_data is not None:
            # Remove existing items
            instance.material_items.all().delete()
            
            # Create new items
            for item_data in material_items_data:
                MaterialVersionItem.objects.create(version=instance, **item_data)
        
        return instance


# Legacy serializer for backward compatibility
class MaterialEntrySerializer(serializers.ModelSerializer):
    """
    Serializer for MaterialEntry model (Legacy).
    """
    class Meta:
        model = MaterialEntry
        fields = ['id', 'entry_date', 'raw_material_product', 'price', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_price(self, value):
        """
        Ensure price is non-negative.
        """
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative.")
        return value

    def validate_raw_material_product(self, value):
        """
        Ensure raw_material_product is not empty.
        """
        if not value or not value.strip():
            raise serializers.ValidationError("Raw material product name is required.")
        return value.strip()
