import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/responsive_scaffold.dart';
import 'screens/chat_screen.dart';
import 'screens/map_screen.dart';
import 'providers/auth.dart';
import 'providers/products.dart';
import 'providers/cart.dart';
import 'providers/favorites.dart';
import 'providers/wallet.dart';
import 'providers/chat_provider.dart';

void main() {
  // Bắt tất cả unhandled exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack: ${details.stack}');
    }
  };

  // Bắt async errors
  runZonedGuarded<Future<void>>(() async {
    runApp(const MyApp());
  }, (error, stack) {
    if (kDebugMode) {
      print('Unhandled Exception: $error');
      print('Stack: $stack');
    }
    // Không crash app, chỉ log lỗi
    if (error is SocketException) {
      if (kDebugMode) {
        print('SocketException: Có thể MySQL server chưa khởi động hoặc kết nối bị đóng');
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cửa hàng đa nền tảng',
        theme: ThemeData(
          // 🎨 Màu chủ đạo: pastel tím-lavender
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF9D8CFF),
            background: const Color(0xFFF8F9FB),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FB),
          useMaterial3: true,

          // 🪄 Font & button style
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Poppins', color: Colors.black87),
            titleMedium: TextStyle(fontWeight: FontWeight.w600),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0x1A6C63FF),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF6C63FF));
              }
              return const IconThemeData(color: Colors.grey);
            }),
          ),
        ),
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    ProductsScreen(onNavigateToProfile: null), // Will be set below
    const ProfileScreen(),
    const ChatScreen(),
    const MapScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
    NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Sản phẩm'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản'),
    NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Trợ lý'),
    NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Bản đồ'),
  ];

  void _onSelect(int idx) {
    setState(() {
      _selectedIndex = idx;
    });
  }

  @override
  void initState() {
    super.initState();
    // Update ProductsScreen with callback
    _pages[1] = ProductsScreen(
      onNavigateToProfile: () => _onSelect(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onSelect,
      destinations: _destinations,
      pages: _pages,
    );
  }
}
