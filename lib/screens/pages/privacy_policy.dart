import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  static const Color primaryBlue = Color(0xFF6239A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0.5,
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Data Privacy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryBlue)),
            SizedBox(height: 15),
            Text("We value your health data. DrugBee ensures that your prescriptions and personal information are encrypted and only shared with verified pharmacy partners to fulfill your specific request.", style: TextStyle(color: Colors.black87, height: 1.6)),
            // Add privacy details here
          ],
        ),
      ),
    );
  }
}
