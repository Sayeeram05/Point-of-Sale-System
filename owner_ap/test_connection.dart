import 'dart:convert';
import 'dart:io';

/// Simple test script to verify Django-Flutter connection
void main() async {
  print('🧪 Testing Django-Flutter Connection...\n');
  
  // Test Categories API
  await testCategoriesAPI();
  
  // Test Products API  
  await testProductsAPI();
  
  print('\n✅ Connection test completed!');
}

Future<void> testCategoriesAPI() async {
  try {
    print('📂 Testing Categories API...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:8000/api/category/'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final categories = jsonDecode(responseBody) as List;
      
      print('✅ Categories API: SUCCESS');
      print('📊 Found ${categories.length} categories:');
      for (var category in categories) {
        print('   - ${category['Name']} (ID: ${category['ID']})');
      }
    } else {
      print('❌ Categories API: FAILED (Status: ${response.statusCode})');
    }
    
    client.close();
  } catch (e) {
    print('❌ Categories API: ERROR - $e');
  }
}

Future<void> testProductsAPI() async {
  try {
    print('\n🧇 Testing Products API...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:8000/api/products/'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final products = jsonDecode(responseBody) as List;
      
      print('✅ Products API: SUCCESS');
      print('📊 Found ${products.length} products:');
      for (var product in products) {
        print('   - ${product['Name']} - ₹${product['Price']} (Category: ${product['ProductCategory']})');
      }
    } else {
      print('❌ Products API: FAILED (Status: ${response.statusCode})');
    }
    
    client.close();
  } catch (e) {
    print('❌ Products API: ERROR - $e');
  }
}