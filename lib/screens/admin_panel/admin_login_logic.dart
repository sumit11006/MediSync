import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/panel/admin_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Handles admin login logic and navigation
Future<void> handleAdminLogin({
  required BuildContext context,
  required String phone,
  required String email,
  required String password,
  required Function(String, {bool isError}) showSnackBar,
  required Function() onComplete,
}) async {
  try {
    // First, try to find by phone only
    QuerySnapshot adminQuery = await FirebaseFirestore.instance
        .collection('Admin_info')
        .where('phone', isEqualTo: phone)
        .get();

    if (adminQuery.docs.isEmpty) {
      showSnackBar(
        "Admin credentials not found! Please setup admin first.",
        isError: true,
      );
      onComplete();
      return;
    }

    // Check if email matches
    bool emailMatch = false;
    for (var doc in adminQuery.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if ((data['email'] ?? '').toString().toLowerCase() ==
          email.toLowerCase()) {
        emailMatch = true;
        break;
      }
    }

    if (!emailMatch) {
      showSnackBar("Email does not match our records!", isError: true);
      onComplete();
      return;
    }

    // Get the first matching document
    var adminData = adminQuery.docs.first.data() as Map<String, dynamic>;
    String storedPassword = adminData['password'] ?? '';

    if (password == storedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_phone', phone);
      await prefs.setBool('is_admin', true);
      showSnackBar("Admin Login Successful!", isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminPanelPage()),
        (route) => false,
      );
    } else {
      showSnackBar("Incorrect password!", isError: true);
    }
    onComplete();
  } catch (e) {
    showSnackBar("Login Error: $e", isError: true);
    onComplete();
  }
}
