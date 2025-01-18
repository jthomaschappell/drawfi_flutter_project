import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tester/screens/path_to_auth_screen/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // print("Hello world 1");
  WidgetsFlutterBinding.ensureInitialized();
  // print("Hello world 2");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  // await dotenv.load();
  // final supabaseUrl = dotenv.env['SUPABASE_URL'];
  // final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
final supabaseUrl = "https://spndakpqcijkgdcicafp.supabase.co";

final supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwbmRha3BxY2lqa2dkY2ljYWZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1ODI1NzEsImV4cCI6MjA0NjE1ODU3MX0.1xdfqEE64YgUbGMWWJue2iCvlRhgvzHwii8sNxNB2_o";

  // Check if any required environment variables are null
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
        "Supabase configuration error: SUPABASE_URL or SUPABASE_ANON_KEY is missing.");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E1F),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

bool isValidEmail(String emailText) {
  final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailPattern.hasMatch(emailText);
}
