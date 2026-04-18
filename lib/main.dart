import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'app_state.dart';
import 'screens/dashboard.dart';
import 'screens/goals.dart';
import 'screens/execution.dart';
import 'screens/profile.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const ErtenApp(),
    ),
  );
}

class AppColors {
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color orangeSoft = Color(0xFFFF9F0A);
  static const Color secondaryTeal = Color(0xFF30D158);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color secondaryDarkGray = Color(0xFF1C1C1E);
  static const Color cardBlack = Color(0xFF1C1C1E);
  static const Color elevatedBlack = Color(0xFF2C2C2E);
  static const Color groupedBlack = Color(0xFF111113);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color separator = Color(0xFF38383A);
}

class ErtenApp extends StatelessWidget {
  const ErtenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERTEN',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundBlack,
        primaryColor: AppColors.primaryOrange,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryOrange,
          secondary: AppColors.orangeSoft,
          surface: AppColors.secondaryDarkGray,
          onPrimary: AppColors.backgroundBlack,
          onSurface: AppColors.textWhite,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w800,
            fontSize: 36,
            letterSpacing: -0.6,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textWhite,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFE5E5EA),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          labelMedium: TextStyle(
            color: AppColors.labelGray,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.secondaryDarkGray,
          contentTextStyle: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const _items = [
    (
      icon: Icons.dashboard_customize_outlined,
      activeIcon: Icons.dashboard_customize,
      label: 'Summary'
    ),
    (icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Goals'),
    (icon: Icons.bolt_outlined, activeIcon: Icons.bolt, label: 'Flow'),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: _goTo),
      const GoalsScreen(),
      const ExecutionScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          Positioned(
            left: 18,
            right: 18,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDarkGray.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.42),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _items.length,
                      (index) => _buildNavItem(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? AppColors.elevatedBlack : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.primaryOrange : AppColors.labelGray,
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
