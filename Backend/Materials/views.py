from datetime import datetime, time, timedelta
from decimal import Decimal

from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import MaterialVersion, MaterialVersionItem, MaterialEntry
from .serializers import (
    MaterialVersionSerializer, MaterialVersionCreateSerializer, 
    MaterialVersionUpdateSerializer, MaterialEntrySerializer
)


class MaterialVersionList(APIView):
    """
    API View for managing material versions.
    """

    def get(self, request, id=None):
        """
        Get a single material version by ID or list all versions.
        """
        if id is not None:
            try:
                version = MaterialVersion.objects.get(id=id)
                serializer = MaterialVersionSerializer(version)
                return Response(serializer.data)
            except MaterialVersion.DoesNotExist:
                return Response(
                    {"error": "Material version not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        # List all versions
        versions = MaterialVersion.objects.all()
        serializer = MaterialVersionSerializer(versions, many=True)
        return Response(serializer.data)

    def post(self, request):
        """
        Create a new material version.
        """
        serializer = MaterialVersionCreateSerializer(data=request.data)
        
        if serializer.is_valid():
            version = serializer.save()
            return Response(
                MaterialVersionSerializer(version).data,
                status=status.HTTP_201_CREATED,
            )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, id):
        """
        Update an existing material version.
        """
        try:
            version = MaterialVersion.objects.get(id=id)
        except MaterialVersion.DoesNotExist:
            return Response(
                {"error": "Material version not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = MaterialVersionUpdateSerializer(version, data=request.data, partial=True)
        
        if serializer.is_valid():
            version = serializer.save()
            return Response(MaterialVersionSerializer(version).data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, id):
        """
        Delete a material version.
        """
        try:
            version = MaterialVersion.objects.get(id=id)
        except MaterialVersion.DoesNotExist:
            return Response(
                {"error": "Material version not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        version.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MaterialVersionForDate(APIView):
    """
    API View for getting material version for a specific date.
    """

    def get(self, request):
        """
        Get the material version effective for a specific date.
        """
        date_param = request.query_params.get("date")
        
        if not date_param:
            return Response(
                {"error": "Date parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            if date_param == "today":
                filter_date = datetime.now().date()
            else:
                filter_date = datetime.strptime(date_param, "%Y-%m-%d").date()
            
            version = MaterialVersion.get_version_for_date(filter_date)
            
            if not version:
                # Return empty version structure when no data found
                empty_version = {
                    'id': '',
                    'name': '',
                    'effective_from_date': filter_date.isoformat(),
                    'is_active': True,
                    'material_items': [],
                    'created_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat(),
                    'total_cost': 0.0,
                    'items_count': 0,
                }
                return Response(empty_version)
            
            serializer = MaterialVersionSerializer(version)
            return Response(serializer.data)
            
        except ValueError:
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"},
                status=status.HTTP_400_BAD_REQUEST,
            )


class MaterialVersionItems(APIView):
    """
    API View for managing material version items.
    """

    def get(self, request, version_id):
        """
        Get all items for a specific material version.
        """
        try:
            version = MaterialVersion.objects.get(id=version_id)
            items = version.material_items.all()
            serializer = MaterialVersionItemSerializer(items, many=True)
            return Response(serializer.data)
        except MaterialVersion.DoesNotExist:
            return Response(
                {"error": "Material version not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

    def post(self, request, version_id):
        """
        Add a new item to a material version.
        """
        try:
            version = MaterialVersion.objects.get(id=version_id)
            data = request.data.copy()
            data['version'] = version.id
            
            serializer = MaterialVersionItemSerializer(data=data)
            
            if serializer.is_valid():
                item = serializer.save()
                return Response(
                    MaterialVersionItemSerializer(item).data,
                    status=status.HTTP_201_CREATED,
                )
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except MaterialVersion.DoesNotExist:
            return Response(
                {"error": "Material version not found"},
                status=status.HTTP_404_NOT_FOUND,
            )


class AvailableMaterials(APIView):
    """
    API View for getting all available raw material products.
    This returns a list of all unique material names across all versions.
    """

    def get(self, request):
        """
        Get all unique material names with their latest prices.
        """
        try:
            # Get unique material names
            material_names = MaterialVersionItem.objects.values_list(
                'material_name', flat=True
            ).distinct()
            
            materials = []
            for name in material_names:
                # Get the latest price for each material
                latest_item = MaterialVersionItem.objects.filter(
                    material_name=name
                ).order_by('-version__effective_from_date').first()
                
                if latest_item:
                    materials.append({
                        'name': name,
                        'price': float(latest_item.price),
                        'version_name': latest_item.version.name,
                        'effective_from': latest_item.version.effective_from_date,
                    })
            
            return Response({
                'materials': sorted(materials, key=lambda x: x['name']),
                'count': len(materials),
            })
            
        except Exception as e:
            return Response(
                {"error": f"Internal server error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# Legacy views for backward compatibility
class MaterialEntryList(APIView):
    """
    Legacy API View for material entries (backward compatibility).
    """

    def get(self, request, id=None):
        """
        Get material entries using the new version system.
        """
        if id is not None:
            try:
                entry = MaterialEntry.objects.get(id=id)
                serializer = MaterialEntrySerializer(entry)
                return Response(serializer.data)
            except MaterialEntry.DoesNotExist:
                return Response(
                    {"error": "Material entry not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        # Get date parameter
        date_param = request.query_params.get("date")
        
        try:
            if date_param == "today" or not date_param:
                filter_date = datetime.now().date()
            else:
                filter_date = datetime.strptime(date_param, "%Y-%m-%d").date()
            
            # Get the version for this date
            version = MaterialVersion.get_version_for_date(filter_date)
            
            if not version:
                # Return empty response if no version found
                return Response({
                    "entries": [],
                    "count": 0,
                    "total": 0.0,
                })
            
            # Convert version items to legacy format
            entries = []
            for item in version.material_items.all():
                entries.append({
                    'id': f"v{version.id}_item{item.id}",
                    'entry_date': filter_date,
                    'raw_material_product': item.material_name,
                    'price': float(item.price),
                    'created_at': item.created_at,
                    'updated_at': item.updated_at,
                })
            
            # Calculate total
            total = sum(entry['price'] for entry in entries)
            
            return Response({
                "entries": entries,
                "count": len(entries),
                "total": total,
            })
            
        except ValueError:
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    def post(self, request):
        """
        Legacy endpoint - redirects to version system.
        """
        return Response(
            {"error": "This endpoint is deprecated. Use material version APIs instead."},
            status=status.HTTP_410_GONE,
        )

    def put(self, request, id):
        """
        Legacy endpoint - redirects to version system.
        """
        return Response(
            {"error": "This endpoint is deprecated. Use material version APIs instead."},
            status=status.HTTP_410_GONE,
        )

    def delete(self, request, id):
        """
        Legacy endpoint - redirects to version system.
        """
        return Response(
            {"error": "This endpoint is deprecated. Use material version APIs instead."},
            status=status.HTTP_410_GONE,
        )


class MaterialEntryTotal(APIView):
    """
    Legacy API View for material totals (backward compatibility).
    """

    def get(self, request):
        """
        Get total price using the new version system.
        """
        date_param = request.query_params.get("date")
        
        try:
            if date_param == "today" or not date_param:
                filter_date = datetime.now().date()
            else:
                filter_date = datetime.strptime(date_param, "%Y-%m-%d").date()
            
            # Get the version for this date
            version = MaterialVersion.get_version_for_date(filter_date)
            
            if not version:
                return Response({
                    "date": date_param or "today",
                    "total": 0.0,
                    "count": 0,
                })
            
            # Calculate total
            total = sum(item.price for item in version.material_items.all())
            
            return Response({
                "date": date_param or "today",
                "total": float(total),
                "count": version.material_items.count(),
            })
            
        except ValueError:
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"},
                status=status.HTTP_400_BAD_REQUEST,
            )
