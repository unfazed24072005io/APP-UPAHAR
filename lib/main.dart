import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // ADD THIS

// Remove DI import if it's causing issues, or create a simple fallback
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with error handling
  try {
    if (!kIsWeb) {
      // Try to initialize DI, but don't block if it fails
      // await di.init();
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo App',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
