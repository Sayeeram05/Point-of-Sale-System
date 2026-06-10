from rest_framework.views import APIView
from rest_framework.response import Response
from .serializers import ColorSerializer, EmojiSerializer

from rest_framework import status
from .models import Color, Emoji


class ColorView(APIView):
    def get(self, request):
        colors = Color.objects.all()
        serializer = ColorSerializer(colors, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data.copy()
        if "color" in data and "HexCode" not in data:
            data["HexCode"] = data["color"]
        if "hex" in data and "HexCode" not in data:
            data["HexCode"] = data["hex"]

        serializer = ColorSerializer(data=data)
        if serializer.is_valid():
            if Color.objects.filter(
                HexCode=serializer.validated_data["HexCode"]
            ).exists():
                return Response(
                    {"message": "Color with this hex code already exists"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, id):
        try:
            color = Color.objects.get(ID=id)
        except Color.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        data = request.data.copy()
        if "color" in data and "HexCode" not in data:
            data["HexCode"] = data["color"]
        if "hex" in data and "HexCode" not in data:
            data["HexCode"] = data["hex"]

        serializer = ColorSerializer(color, data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, id):
        try:
            color = Color.objects.get(ID=id)
        except Color.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        color.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class EmojiView(APIView):
    def get(self, request):
        emojis = Emoji.objects.all()
        serializer = EmojiSerializer(emojis, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data.copy()
        if "emoji_text" in data and "Emoji" not in data:
            data["Emoji"] = data["emoji_text"]
        if "emoji" in data and "Emoji" not in data:
            data["Emoji"] = data["emoji"]

        serializer = EmojiSerializer(data=data)
        if serializer.is_valid():
            if Emoji.objects.filter(Emoji=serializer.validated_data["Emoji"]).exists():
                return Response(
                    {"message": "Emoji with this unicode already exists"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, id):
        try:
            emoji = Emoji.objects.get(ID=id)
        except Emoji.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        data = request.data.copy()
        if "emoji_text" in data and "Emoji" not in data:
            data["Emoji"] = data["emoji_text"]
        if "emoji" in data and "Emoji" not in data:
            data["Emoji"] = data["emoji"]

        serializer = EmojiSerializer(emoji, data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, id):
        try:
            emoji = Emoji.objects.get(ID=id)
        except Emoji.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        emoji.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
