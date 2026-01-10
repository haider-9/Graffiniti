import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'pages/camera_page.dart';
import 'pages/discover_page.dart';
import 'pages/search_page.dart';
import 'pages/simple_profile_page.dart';
import 'core/widgets/custom_bottom_navigation.dart';
import 'core/widgets/auth_wrapper.dart';
import 'ui/community/widgets/communities_screen.dart';
import 'config/dependencies.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Dependencies.getProviders(),
      child: MaterialApp(
        title: 'Graffiniti',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
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
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DiscoverPage(),
    SearchPage(),
    CameraPage(),
    CommunitiesScreen(),
    SimpleProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Set initial camera page visibility (camera is at index 2, default is 0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CameraPageController.setPageVisible(false);
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);

    // Notify camera page about visibility changes
    CameraPageController.setPageVisible(index == 2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.jumpToPage(index);
          _onPageChanged(index);
        },
      ),
    );
  }
}
