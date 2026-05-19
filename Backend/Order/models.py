from django.db import models
from Auxiliary.models import Color, Emoji
from Product.models import Product


class Order(models.Model):
    ID = models.AutoField(primary_key=True)
    ColorId = models.ForeignKey(Color, on_delete=models.SET_NULL, null=True, blank=True)
    EmojiId = models.ForeignKey(Emoji, on_delete=models.SET_NULL, null=True, blank=True)
    TotalQuantity = models.IntegerField(default=0)
    UpiAmount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    CashAmount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    Completed = models.BooleanField(default=False)
    CreatedAt = models.DateTimeField(auto_now_add=True)
    UpdatedAt = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Order {self.ID}"


class OrderItem(models.Model):
    ID = models.AutoField(primary_key=True)
    OrderId = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='OrderItems')
    ProductID = models.ForeignKey(Product, on_delete=models.CASCADE)
    Quantity = models.IntegerField(default=1)
    PriceAtPurchase = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.ProductID} - {self.Quantity}"