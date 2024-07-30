import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pathpal/screens/auth.dart';
import 'package:pathpal/screens/tabs.dart';
import 'firebase_options.dart';

//need to fix app icon on android

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathPal',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 180, 221, 255),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const SplashScreen();
          // }
          if (snapshot.hasData) {
            return Tabs();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
