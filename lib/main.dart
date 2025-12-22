import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/news/presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: NewsReaderApp()));
}

class NewsReaderApp extends StatelessWidget {
  const NewsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
