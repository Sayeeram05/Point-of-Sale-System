from django.db import models
from Category.models import Category

class Product(models.Model):
    ID = models.AutoField(primary_key=True)
    Name = models.CharField(max_length=255)
    Price = models.DecimalField(max_digits=10, decimal_places=2)
    ProductCategory = models.ForeignKey(Category, on_delete=models.CASCADE)
    Deleted = models.BooleanField(default=False)
    Image = models.ImageField(upload_to='products/', null=True, blank=True)

    def __str__(self):
        return f"{self.Name} - ₹{self.Price}"