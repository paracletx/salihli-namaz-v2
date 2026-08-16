import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Durum çubuğunu koyu arka planla uyumlu, sade tutuyoruz.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const SalihliNamazVaktiApp());
}

class SalihliNamazVaktiApp extends StatelessWidget {
  const SalihliNamazVaktiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salihli Namaz Vakitleri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8C077),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      // Uygulama doğrudan namaz vakitleri ekranıyla açılır; konum seçimi,
      // giriş ekranı veya ayarlar yoktur.
      home: const HomeScreen(),
    );
  }
}
