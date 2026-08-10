import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const Color primaryColor = Color(
    0xFF6239A1,
  ); // Using your primary blue/purple

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link")));
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app")),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open phone app")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- FAQs SECTION ---
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 15),

          // Category 1: General
          const Text(
            "General & Account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          _buildFAQ(
            "What is DrugBee?",
            "DrugBee is a specialized healthcare platform designed to connect patients and their families with verified vendors to source rare, critical, and hard-to-find medicines.",
          ),
          _buildFAQ(
            "How do I create an account?",
            "You can easily sign up using your phone number. We use a secure, OTP-based login system to verify your identity and keep your account safe.",
          ),
          _buildFAQ(
            "Is my medical data secure?",
            "Absolutely. We use strict encryption protocols. Your prescriptions and health information are only shared with verified vendors to fulfill your specific requests.",
          ),
          const SizedBox(height: 15),

          // Category 2: Orders & Tracking
          const Text(
            "Ordering & Tracking",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          _buildFAQ(
            "How do I request a rare medicine?",
            "Go to the 'Request Medicine' section. Enter the medicine name, upload a clear photo of your doctor's prescription, and submit. Our network will begin sourcing it immediately.",
          ),
          _buildFAQ(
            "Do I need a prescription?",
            "Yes. For all critical injections and Rx-category drugs, a valid prescription from a Registered Medical Practitioner is legally required. OTC products do not require one.",
          ),
          _buildFAQ(
            "Can I return a medicine?",
            "Due to strict safety, hygiene, and temperature-control standards for rare medicines, we do not accept returns. If you receive a damaged item, contact support within 48 hours.",
          ),
          const SizedBox(height: 15),

          // Category 3: Donations & Payments
          const Text(
            "Donations & Payments",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          _buildFAQ(
            "How does the Donate feature work?",
            "We run a patient assistance program to help families who cannot afford rare treatments. You can contribute by selecting an amount and paying directly via your UPI app.",
          ),
          _buildFAQ(
            "Are there hidden fees when I donate?",
            "No! We use direct UPI deep-linking to bypass third-party payment gateway fees. 100% of your contribution goes toward patient assistance.",
          ),
          _buildFAQ(
            "My payment failed but money was deducted.",
            "Since transactions happen directly through the UPI network, any failed payments are automatically refunded by your bank, usually within 3 to 5 business days.",
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSupportCard(
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          sub,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFAQ(String q, String a) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ), // Removes the border lines when expanded
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          q,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0, right: 15.0),
            child: Text(
              a,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
