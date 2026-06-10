import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/woffle_dashboard_page.dart';
import 'theme/woffle_app_theme.dart';
import 'services/woffle_app_performance.dart';
import 'services/woffle_network_config.dart';
import 'services/woffle_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize network configuration for API connections
  NetworkConfig.configureCertificates();

  // Initialize performance optimizations
  AppPerformance.initialize();

  // Load saved IP and configure API
  final prefs = await SharedPreferences.getInstance();
  final savedIp = prefs.getString('server_ip');
  if (savedIp != null && savedIp.isNotEmpty) {
    ApiService.configure(baseUrl: 'http://$savedIp');
  }

  // NOTE: We no longer clear the entire image cache on startup.
  // The cache manager already handles staleness via its 7-day TTL.
  // Clearing on every launch was the root cause of images not loading
  // on the first order open (they had to re-download each time).

  // Enhanced system UI overlay style for better performance and appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );  

  // Lock to portrait orientation only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Enable hardware acceleration if available
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const BillApp());
}

class BillApp extends StatelessWidget {
  const BillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woffle',
      theme: AppTheme.lightTheme,
      home: const _IpGate(),
      debugShowCheckedModeBanner: false,

      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Use centralized text scaling
            textScaler: TextScaler.linear(
              AppPerformance.getTextScaleFactor(context),
            ),
          ),
          child: child!,
        );
      },

      // Enhanced scroll behavior for better performance
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: AppPerformance.getOptimizedScrollPhysics(),
        scrollbars: false, // Disable scrollbars for better performance
      ),

      // Optimize theme mode
      themeMode: ThemeMode.light,

      // Disable unnecessary features for better performance
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
    );
  }
}

/// Gate widget that checks for server IP on first launch.
class _IpGate extends StatefulWidget {
  const _IpGate();

  @override
  State<_IpGate> createState() => _IpGateState();
}

class _IpGateState extends State<_IpGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkIp();
  }

  Future<void> _checkIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp == null || savedIp.isEmpty) {
      if (mounted) {
        setState(() => _checking = false);
        _showIpDialog();
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    }
  }

  Future<void> _showIpDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Server Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the server IP address and port to connect.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'IP Address:Port',
                hintText: '192.168.1.100:8000',
                prefixIcon: const Icon(Icons.dns),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isEmpty) return;
              final parts = ip.split(':');
              if (parts.length != 2) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Format must be IP:Port, e.g. 192.168.1.1:8000',
                    ),
                  ),
                );
                return;
              }
              final port = int.tryParse(parts[1]);
              if (port == null || port < 1 || port > 65535) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid port number')),
                );
                return;
              }
              Navigator.pop(ctx, ip);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', result);
      ApiService.configure(baseUrl: 'http://$result');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
