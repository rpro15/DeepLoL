import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/meme_feed_screen.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MemeFeedScreen(),
    );
  }
}
