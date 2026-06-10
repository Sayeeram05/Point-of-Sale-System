from django.contrib import admin
from .models import RawMaterial, PurchaseRecord, PurchaseItem


@admin.register(RawMaterial)
class RawMaterialAdmin(admin.ModelAdmin):
    list_display = ['name', 'unit', 'base_price', 'is_active', 'updated_at']
    list_filter = ['is_active']
    search_fields = ['name']
    list_editable = ['base_price', 'is_active']


class PurchaseItemInline(admin.TabularInline):
    model = PurchaseItem
    extra = 0
    readonly_fields = ['subtotal']
    fields = ['raw_material', 'material_name', 'base_price_snapshot', 'quantity', 'subtotal']


@admin.register(PurchaseRecord)
class PurchaseRecordAdmin(admin.ModelAdmin):
    list_display = ['target_date', 'total_cost', 'is_locked', 'created_at', 'updated_at']
    list_filter = ['is_locked']
    date_hierarchy = 'target_date'
    readonly_fields = ['total_cost', 'created_at', 'updated_at']
    inlines = [PurchaseItemInline]
