from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = '__all__'

    def get_image_url(self, obj):
        if obj.Image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.Image.url)
            return obj.Image.url
        return None