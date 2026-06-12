from django.db import models


class RawMaterial(models.Model):
    """Master catalog of purchasable raw ingredients."""
    name = models.CharField(max_length=200, unique=True)
    unit = models.CharField(max_length=50, default='kg')
    base_price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'Raw Material'
        verbose_name_plural = 'Raw Materials'

    def __str__(self):
        return f"{self.name} (Rs.{self.base_price}/{self.unit})"


class PurchaseRecord(models.Model):
    """
    One purchase record per calendar date (unique=True on target_date).
    is_locked=True means the record is finalized and read-only in the UI.
    """
    target_date = models.DateField(unique=True)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    is_locked = models.BooleanField(default=True)
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-target_date']
        verbose_name = 'Purchase Record'
        verbose_name_plural = 'Purchase Records'

    def __str__(self):
        return f"Purchase Record — {self.target_date} (locked={self.is_locked})"


class PurchaseItem(models.Model):
    """
    Individual line item inside a PurchaseRecord.
    Stores a snapshot of material name + price at the moment of saving,
    ensuring historical accuracy even if the master RawMaterial is later edited.
    """
    record = models.ForeignKey(
        PurchaseRecord,
        on_delete=models.CASCADE,
        related_name='items',
    )
    # FK kept for traceability; set to NULL if master material is deleted
    raw_material = models.ForeignKey(
        RawMaterial,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    # Snapshot fields — frozen at save time for historical accuracy
    material_name = models.CharField(max_length=200)
    base_price_snapshot = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.DecimalField(max_digits=10, decimal_places=3)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    class Meta:
        ordering = ['id']
        verbose_name = 'Purchase Item'
        verbose_name_plural = 'Purchase Items'

    def save(self, *args, **kwargs):
        # Auto-compute subtotal before every save
        self.subtotal = self.base_price_snapshot * self.quantity
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.material_name} x {self.quantity} = Rs.{self.subtotal}"
