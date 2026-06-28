import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DeepLoLApp());
}

class DeepLoLApp extends StatelessWidget {
  const DeepLoLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepLoL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accent,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentLight,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
