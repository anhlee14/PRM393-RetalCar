import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const AutoRentalApp());
}

class AutoRentalApp extends StatelessWidget {
  const AutoRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoRental - Đặt Xe Nhanh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
