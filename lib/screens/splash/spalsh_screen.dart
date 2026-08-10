import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:drugbee/panel/admin_panel.dart'; // Import Admin Panel
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure these imports match your folder structure
import '../auth/welcome_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../pages/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleFlow();
  }

  Future<void> _handleFlow() async {
    // 1. Minimum Splash Duration
    await Future.delayed(const Duration(seconds: 2));

    // 2. Load SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    final String? userPhone = prefs.getString('user_login_phone') ?? prefs.getString('user_phone');
    final String adminPhone = prefs.getString('admin_phone') ?? "";
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final bool isAdmin = prefs.getBool('is_admin') ?? false;

    if (!mounted) return;

    // --- 3. DECIDE NAVIGATION LOGIC ---

    // A. Check for Admin Session FIRST
    if (isAdmin && adminPhone.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelPage()),
      );
      return; // Stop execution here if admin
    }

    // B. Check for Standard User Session
    if (userPhone != null && userPhone.isNotEmpty) {

      // Fallback: Just in case a user was promoted to admin in Firestore
      // but SharedPreferences hasn't updated yet.
      try {
        // MATCHED COLLECTION NAME TO ADMIN LOGIN: 'Admin_info'
        QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
            .collection('Admin_info')
            .where('phone', isEqualTo: userPhone)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // They are actually an admin! Update prefs and route.
          await prefs.setBool('is_admin', true);
          await prefs.setString('admin_phone', userPhone);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminPanelPage()),
          );
          return;
        }
      } catch (e) {
        print("Error checking fallback admin status: $e");
      }

      // If not an admin, send to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    // C. No one is logged in -> Check Onboarding Status
    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary, // Or Color(0xFF6239A1)
              const Color(0xFFFFA94D),
              const Color(0xFF6239A1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.medication_rounded, size: 100, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'DrugBee',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
