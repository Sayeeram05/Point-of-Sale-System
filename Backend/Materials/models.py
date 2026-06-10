from django.db import models
from django.core.validators import MinValueValidator


class MaterialVersion(models.Model):
    """
    Model for storing material configuration versions with effective dates.
    Each version represents a snapshot of material configuration that applies
    from effective_from_date until the next version starts.
    """
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255, help_text="Version name for identification")
    effective_from_date = models.DateField(db_index=True, help_text="Date from which this version is effective")
    is_active = models.BooleanField(default=True, help_text="Whether this version is currently active")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'material_versions'
        ordering = ['-effective_from_date', '-created_at']
        verbose_name = 'Material Version'
        verbose_name_plural = 'Material Versions'
        unique_together = ['effective_from_date']

    def __str__(self):
        return f"Version {self.name} (Effective: {self.effective_from_date})"

    @classmethod
    def get_version_for_date(cls, date):
        """Get the latest version effective on or before the given date"""
        return cls.objects.filter(
            effective_from_date__lte=date,
            is_active=True
        ).order_by('-effective_from_date').first()


class MaterialVersionItem(models.Model):
    """
    Model for storing individual material items within a version.
    This represents the actual materials with their prices for a specific version.
    """
    id = models.AutoField(primary_key=True)
    version = models.ForeignKey(
        MaterialVersion,
        on_delete=models.CASCADE,
        related_name='material_items',
        help_text="The version this material belongs to"
    )
    material_name = models.CharField(max_length=255, help_text="Name of the raw material")
    price = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Price of the material"
    )
    quantity = models.PositiveIntegerField(
        default=1,
        validators=[MinValueValidator(1)],
        help_text="Quantity of the material"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'material_version_items'
        ordering = ['material_name']
        verbose_name = 'Material Version Item'
        verbose_name_plural = 'Material Version Items'
        unique_together = ['version', 'material_name']

    def __str__(self):
        return f"{self.material_name} - ₹{self.price} (Version: {self.version.name})"


# Keep the old MaterialEntry model for backward compatibility during migration
class MaterialEntry(models.Model):
    """
    Legacy model for storing raw material entries.
    This is kept for backward compatibility but should be deprecated.
    """
    id = models.AutoField(primary_key=True)
    entry_date = models.DateField(db_index=True)
    raw_material_product = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'material_entries'
        ordering = ['-entry_date', '-created_at']
        verbose_name = 'Material Entry (Legacy)'
        verbose_name_plural = 'Material Entries (Legacy)'

    def __str__(self):
        return f"{self.raw_material_product} - ₹{self.price} ({self.entry_date})"
