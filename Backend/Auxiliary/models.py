from django.db import models

class Color(models.Model):
    ID = models.AutoField(primary_key=True)
    HexCode = models.CharField(max_length=7)

    def __str__(self):
        return self.HexCode

class Emoji(models.Model):
    ID = models.AutoField(primary_key=True)
    Emoji = models.CharField(max_length=10)

    def __str__(self):
        return self.Emoji
