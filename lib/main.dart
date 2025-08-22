import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/profile_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Griffiniti',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
          primary: Colors.white,
          secondary: Colors.white70,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
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
  
  final List<Widget> _pages = [
    const HomePage(),
    const Placeholder(),
    const CameraPage(),
    const Placeholder(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.bookmark_rounded, 1),
            _buildCenterButton(),
            _buildNavItem(Icons.photo_library_rounded, 3),
            _buildNavItem(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white54,
          size: isSelected ? 28 : 24,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isCameraPage = _selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = 2);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isCameraPage ? Colors.white : Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            if (isCameraPage)
              BoxShadow(
                color: Colors.white.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCameraPage ? Colors.white : Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: isCameraPage ? Colors.black : Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
