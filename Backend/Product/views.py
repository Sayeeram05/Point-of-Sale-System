from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Product
from Category.models import Category
from .serializers import ProductSerializer

class ProductList(APIView):
    def get(self, request):
        products = Product.objects.filter(Deleted=False)
        serializer = ProductSerializer(products, many=True)
        if not serializer.data:
            return Response({"message": "No products found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(serializer.data)

    def post(self, request):
        serializer = ProductSerializer(data=request.data)
        if serializer.is_valid():
            category_id = request.data.get('category')
            try:
                category = Category.objects.get(id=category_id)
                serializer.save(ProductCategory=category)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            except Category.DoesNotExist:
                return Response({'error': 'Category not found'}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, id):
        try:
            product = Product.objects.get(ID=id)
            print(product,request.data)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = ProductSerializer(product, data=request.data)
        if serializer.is_valid():
            category_id = request.data.get('ProductCategory')
            try:
                category = Category.objects.get(ID=category_id)
                serializer.save(ProductCategory=category)
                return Response(serializer.data, status=status.HTTP_200_OK)
            except Category.DoesNotExist:
                return Response({'error': 'Category not found'}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, id):
        try:
            product = Product.objects.get(ID=id)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        product.Deleted = True
        product.save()
        return Response(status=status.HTTP_204_NO_CONTENT)
    

class ProductDetail(APIView):
    def get(self, request, id):
        try:
            product = Product.objects.get(ID=id, Deleted=False)
            serializer = ProductSerializer(product)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

class ProductByCategory(APIView):
    def get(self, request, category_id):
        products = Product.objects.filter(ProductCategory=category_id, Deleted=False)
        serializer = ProductSerializer(products, many=True)
        if not serializer.data:
            return Response({"message": "No products found for this category"}, status=status.HTTP_404_NOT_FOUND)
        return Response(serializer.data, status=status.HTTP_200_OK)


