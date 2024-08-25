import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pathpal/data/airport_database.dart';
import 'package:pathpal/screens/auth.dart';
import 'package:pathpal/screens/tabs.dart';
import 'package:pathpal/screens/email_verification_screen.dart';
import 'firebase_options.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AirportDatabase.instance.database;
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
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 180, 221, 255),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return FutureBuilder<User?>(
              future: FirebaseAuth.instance.currentUser
                  ?.reload()
                  .then((_) => FirebaseAuth.instance.currentUser),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (userSnapshot.hasData && userSnapshot.data!.emailVerified) {
                  return const Tabs();
                } else {
                  return const EmailVerificationScreen();
                }
              },
            );
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
