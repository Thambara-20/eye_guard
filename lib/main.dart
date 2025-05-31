import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import services
import 'services/notification_service.dart';
import 'services/sensor_service.dart';
import 'services/storage_service.dart';
import 'services/light_monitor_service.dart';

// Import screens
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

// Import theme
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.init();

  final sensorService = SensorService();
  final storageService = StorageService();

  final monitorService = LightMonitorService(
    sensorService: sensorService,
    storageService: storageService,
    notificationService: notificationService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<LightMonitorService>.value(value: monitorService),
        Provider<StorageService>.value(value: storageService),
      ],
      child: const EyeGuardApp(),
    ),
  );
}

class EyeGuardApp extends StatelessWidget {
  const EyeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyeGuard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final monitorService =
        Provider.of<LightMonitorService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Initialize screens
    _screens = [
      HomeScreen(
        monitorService: monitorService,
        storageService: storageService,
      ),
      StatsScreen(
        monitorService: monitorService,
        storageService: storageService,
      ),
      SettingsScreen(
        storageService: storageService,
      ),
    ];

    // Start monitoring when the app is launched
    monitorService.startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
