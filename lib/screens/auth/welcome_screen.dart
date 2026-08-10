import 'package:drugbee/screens/auth/login_screen.dart';
import 'package:drugbee/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF6239A1);
    final secondaryOrange = const Color(0xFFFFA94D);

    return Scaffold(
      body: Container(
        height: MediaQuery.of
          (context)
          .size.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, secondaryOrange],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 185),
            // 🐝 Modern Logo Section
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: Icon(Icons.medication_rounded, size: 55, color: Color(0xFF6239A1)),
            ),
            const SizedBox(height: 30),
            Text(
              "DrugBee",
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Medicine sourcing made simple",
              style: TextStyle(color: Colors.white, fontSize: 19),
            ),
            const Spacer(),


            Container(
              padding: const EdgeInsets.all(55),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Welcome",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "End your search for rare medicines. We help you source what others can't",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16,fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 32),


                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [primaryBlue, secondaryOrange]),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SignUpScreen(),),
                        );
                      }, // Navigate to Sign Up
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text("Create New Account", style: TextStyle(color: Colors.white, fontSize: 19,fontWeight: FontWeight.w600),),
                    ),
                  ),

                  const SizedBox(height: 16),


                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginScreen()),
                      );
                        }, // Navigate to Login
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Log In", style: TextStyle(color: primaryBlue,fontSize: 19,fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
