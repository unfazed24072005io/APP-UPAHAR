import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // detect web
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'di_container.dart' as di;
import 'helper/custom_delegate.dart';
import 'localization/app_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI container
  if (!kIsWeb) {
    try {
      await di.init(); // only initialize DI on non-web
    } catch (_) {}
  }

  // Run app
  runApp(
    MultiProvider(
      providers: [
        // minimal providers needed for SplashScreen
        ChangeNotifierProvider(create: (_) => di.sl<SplashController>()),
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
            child: child!);
      },
    );
  }
}
