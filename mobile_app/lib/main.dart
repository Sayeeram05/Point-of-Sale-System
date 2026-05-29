import 'package:flutter/material.dart';
import 'models/api_models.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/pos_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waffle Day',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE67E22),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF8F0),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B1A00),
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF5F3B18)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFF0E0),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<CartItemModel> _cartItems = [];
  final GlobalKey<OrdersPageState> _ordersPageKey =
      GlobalKey<OrdersPageState>();

  void _addToCart(ProductData product) {
    if (product.id == null) return;

    final existingIndex = _cartItems.indexWhere(
      (item) => item.id == product.id,
    );
    setState(() {
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += 1;
      } else {
        _cartItems.add(
          CartItemModel(
            id: product.id!,
            name: product.name,
            price: product.price,
            quantity: 1,
          ),
        );
      }
    });
  }

  void _increaseCartItem(int productId) {
    final existingIndex = _cartItems.indexWhere((item) => item.id == productId);
    if (existingIndex >= 0) {
      setState(() {
        _cartItems[existingIndex].quantity += 1;
      });
    }
  }

  void _decreaseCartItem(int productId) {
    final existingIndex = _cartItems.indexWhere((item) => item.id == productId);
    if (existingIndex >= 0) {
      setState(() {
        final current = _cartItems[existingIndex];
        if (current.quantity > 1) {
          current.quantity -= 1;
        } else {
          _cartItems.removeAt(existingIndex);
        }
      });
    }
  }

  void _removeCartItem(int productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == productId);
    });
  }

  void _onOrderCompleted() {
    setState(() {
      _cartItems.clear();
      _currentIndex = 2;
    });
    _ordersPageKey.currentState?.refreshOrders();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onAddToCart: _addToCart, cartItems: _cartItems),
      CartPage(
        cartItems: _cartItems,
        onIncrease: _increaseCartItem,
        onDecrease: _decreaseCartItem,
        onRemove: _removeCartItem,
        onOrderCompleted: _onOrderCompleted,
      ),
      OrdersPage(key: _ordersPageKey),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
