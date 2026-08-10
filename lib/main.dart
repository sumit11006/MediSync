import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drugbee/screens/splash/spalsh_screen.dart'; // Ensure spelling matches your file
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Failed to load .env: $e');
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const DrugBeeApp());
}

class DrugBeeApp extends StatelessWidget {
  const DrugBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DrugBee',
        theme: buildAppTheme(),
      
        home: const SplashScreen(),
      ),
    );
  }
}