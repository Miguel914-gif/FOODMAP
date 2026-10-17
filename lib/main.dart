import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const FoodMapApp());
}

class FoodMapApp extends StatelessWidget {
  const FoodMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FOODMAP',
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
