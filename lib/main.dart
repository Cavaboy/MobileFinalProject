import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  // Request notification permission for Android 13+
  await NotificationService.requestPermissionIfNeeded();
  runApp(const NomadDailyApp());
}

class NomadDailyApp extends StatelessWidget {
  const NomadDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'NomadDaily',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.user == null) {
              return const LoginScreen();
            } else {
              return const MainNavigation();
            }
          },
        ),
        // Set the app icon for splash and launcher (for in-app use, e.g. splash screen)
        builder: (context, child) {
          return child!;
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    ConverterScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Nearby'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Converter',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
