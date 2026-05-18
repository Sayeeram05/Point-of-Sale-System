from rest_framework.views import APIView
from rest_framework.response import Response
from .serializers import CategorySerializer
from rest_framework import status
from .models import Category

class CategoryView(APIView):

    def get(self, request):
        Data = Category.objects.all()
        serializers = CategorySerializer(Data, many=True)
        return Response(serializers.data, status=status.HTTP_200_OK)
    
    def post(self, request):
        serializer = CategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, id):
        try:
            category = Category.objects.get(ID=id)
            print(category,request.data)
        except Category.DoesNotExist:
            return Response({"error": "Category not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = CategorySerializer(category, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, id):
        try:
            category = Category.objects.get(ID=id)
        except Category.DoesNotExist:
            return Response({"error": "Category not found"}, status=status.HTTP_404_NOT_FOUND)

        category.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    