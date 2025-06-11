import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/profile_screen.dart' as profile;
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
    // Define your brand color
    const Color brandBlue = Color(0xFF37A2EF); // Your specified brand color

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'NomadDaily',
        debugShowCheckedModeBanner: false, // Remove the debug ribbon
        theme: ThemeData(
          // Define a light color scheme using your brand blue
          colorScheme: ColorScheme.light(
            primary: brandBlue, // Your brand blue for primary elements
            onPrimary: Colors.white, // Text/icons on primary color
            secondary: brandBlue, // Use brand blue for secondary accents too
            onSecondary: Colors.white, // Text/icons on secondary color
            surface: Colors.white, // Card/sheet backgrounds
            background: Colors.white, // Main background
            error: Colors.red, // Standard error color
            onBackground: const Color(0xFF212121), // Primary text color
            onSurface: const Color(0xFF212121), // Text on surfaces
          ),
          scaffoldBackgroundColor:
              Colors.white, // Clean white background for all scaffolds
          fontFamily:
              'Inter', // Suggesting 'Inter' font (requires Google Fonts package)
          // If not using Google Fonts, remove this line to use system default.

          // AppBar Theme for a minimalist look
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white, // White app bar background
            elevation: 0, // No shadow for a flat design
            foregroundColor: Color(
              0xFF212121,
            ), // Dark grey for app bar text/icons
            centerTitle: true, // Center app bar title for a clean look
          ),

          // Bottom Navigation Bar Theme
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white, // White background for the bar
            selectedItemColor: brandBlue, // Brand blue for selected items
            unselectedItemColor: Color(
              0xFF757575,
            ), // Medium grey for unselected items
            elevation: 0, // No shadow for a flat look
            type: BottomNavigationBarType.fixed, // Ensure all items are visible
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ), // Bold label for selected item
          ),
          useMaterial3: true, // Opt-in to Material 3
        ),
        home: const AppLauncher(),
        builder: (context, child) {
          return child!;
        },
      ),
    );
  }
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.user == null) {
          return const LoginScreen();
        } else {
          return MainNavigation();
        }
      },
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
    profile.ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will automatically pick up the scaffoldBackgroundColor from the theme
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ), // Using rounded icons for modern feel
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Converter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
