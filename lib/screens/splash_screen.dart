import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal do FOODMAP
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            // Nome do aplicativo
            const Text(
              'FOODMAP',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFF2D2D2D),
              ),
            ),

            const SizedBox(height: 10),

            // Slogan
            const Text(
              'Encontre. Descubra. Avalie.',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777)),
            ),

            const SizedBox(height: 50),

            // Indicador de carregamento
            const CircularProgressIndicator(color: Color(0xFFFF6B35)),
          ],
        ),
      ),
    );
  }
}
