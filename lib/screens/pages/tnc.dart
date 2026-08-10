import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});
  static const Color primaryBlue = Color(0xFF6239A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0.5,
        title: const Text("Terms & Conditions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text("1. Acceptance of Terms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("By using DrugBee, you agree to comply with our healthcare guidelines and verify that you possess a valid prescription for requested medicines.", style: TextStyle(color: Colors.black87, height: 1.5)),
            SizedBox(height: 20),
            Text("2. Medicine Availability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("DrugBee is a discovery platform. Availability is subject to third-party licensed vendors and is not guaranteed for every request.", style: TextStyle(color: Colors.black87, height: 1.5)),
            // Add more terms as needed
          ],
        ),
      ),
    );
  }
}
