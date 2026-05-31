import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase ကိုပါ အောက်ပါအတိုင်း စတင်ပေးပါ
  await Supabase.initialize(
    url: 'https://wmlfrcxapqwcfkcndxsg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndtbGZyY3hhcHF3Y2ZrY25keHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNTAzODksImV4cCI6MjA5NDkyNjM4OX0.6kC7ovE0EAwb5iTuwJRaimLPUhDQ7ArokaFgI-W6N3Q',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const AutoHutApp(),
    ),
  );
}

class AutoHutApp extends StatelessWidget {
  const AutoHutApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AutoHut',
    theme: AppTheme.light,
    home: const MainScreen(),
    debugShowCheckedModeBanner: false,
  );
}