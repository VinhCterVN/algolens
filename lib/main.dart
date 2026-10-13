import 'package:algolens/core/theme/app_theme.dart';
import 'package:algolens/features/home/presentation/views/home_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlgoLens',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeView(),
    );
  }
}
