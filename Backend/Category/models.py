from django.db import models

class Category(models.Model):
    ID = models.AutoField(primary_key=True)
    Name = models.CharField(max_length=255, unique=True)
    
    def __str__(self):
        return self.Name
    


