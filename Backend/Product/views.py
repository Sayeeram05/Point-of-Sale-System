from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Product
from Category.models import Category
from .serializers import ProductSerializer
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

@method_decorator(csrf_exempt, name='dispatch')
class ProductList(APIView):
    def get(self, request):
        products = Product.objects.filter(Deleted=False)
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        try:
            # Get category ID from request data
            category_id = request.data.get('category') or request.data.get('ProductCategory')
            if not category_id:
                return Response({'error': 'Category ID is required'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Find category by ID (using correct field name)
            try:
                category = Category.objects.get(ID=category_id)
            except Category.DoesNotExist:
                return Response({'error': 'Category not found'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Create product data with proper category reference
            product_data = request.data.copy()
            product_data['ProductCategory'] = category.ID
            
            serializer = ProductSerializer(data=product_data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def put(self, request, id):
        try:
            product = Product.objects.get(ID=id)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        try:
            # Handle category update if provided
            category_id = request.data.get('ProductCategory') or request.data.get('category')
            if category_id:
                try:
                    category = Category.objects.get(ID=category_id)
                    product_data = request.data.copy()
                    product_data['ProductCategory'] = category.ID
                except Category.DoesNotExist:
                    return Response({'error': 'Category not found'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                product_data = request.data
            
            serializer = ProductSerializer(product, data=product_data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def delete(self, request, id):
        try:
            product = Product.objects.get(ID=id)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        product.Deleted = True
        product.save()
        return Response(status=status.HTTP_204_NO_CONTENT)
    

@method_decorator(csrf_exempt, name='dispatch')
class ProductDetail(APIView):
    def get(self, request, id):
        try:
            product = Product.objects.get(ID=id, Deleted=False)
            serializer = ProductSerializer(product)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

@method_decorator(csrf_exempt, name='dispatch')
class ProductByCategory(APIView):
    def get(self, request, category_id):
        products = Product.objects.filter(ProductCategory=category_id, Deleted=False)
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


