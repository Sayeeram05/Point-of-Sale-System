from rest_framework import serializers
from .models import Color, Emoji

class ColorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Color
        fields = ['ID', 'HexCode']

class EmojiSerializer(serializers.ModelSerializer):
    class Meta:
        model = Emoji
        fields = ['ID', 'Emoji']