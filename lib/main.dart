import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taskgenius/firebase_options.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/screens/add_task_screen.dart';
import 'package:taskgenius/screens/dashboard_screen.dart';
import 'package:taskgenius/screens/home_screen.dart';
import 'package:taskgenius/screens/account_screen.dart';
import 'package:taskgenius/screens/splash_screen.dart';
import 'package:taskgenius/state/notification_provider.dart';
import 'package:taskgenius/state/task_provider.dart';
import 'package:taskgenius/state/auth_provider.dart';
import 'package:taskgenius/state/theme_provider.dart';
import 'package:taskgenius/utils/theme_config.dart';
import 'package:taskgenius/services/notification_service.dart';

// Initialize Firebase
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  static bool _providerConnected = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AI Task Manager',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routes: {
              '/': (context) => const AppRouter(),
              '/home': (context) => const MainAppScaffold(),
            },
            initialRoute: '/',
            // Key change: Connect providers after the app is built
            builder: (context, child) {
              // Use a static flag to ensure this only runs once
              if (!_providerConnected) {
                _providerConnected = true;

                // Schedule this for after the frame is rendered
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint(
                    "Setting notification provider (one-time setup)...",
                  );
                  final notificationProvider =
                      Provider.of<NotificationProvider>(context, listen: false);
                  NotificationService.instance.setNotificationProvider(
                    notificationProvider,
                  );
                });
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}

// Router widget that decides what to show based on auth state
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('Auth state changed. isLoggedIn: ${authProvider.isLoggedIn}');

        // If loading, show a loading screen
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not logged in, show authentication flow
        if (!authProvider.isLoggedIn) {
          return const SplashScreen();
        }

        // If user is logged in, show main app
        return const MainAppScaffold();
      },
    );
  }
}

// Main app scaffold with bottom navigation
class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Main app screens
    final List<Widget> screens = [
      const HomeScreen(),
      const TaskInputScreen(),
      const AccountScreen(),
      const DashboardScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Task',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();
  runApp(const TaskManagerApp());
}
