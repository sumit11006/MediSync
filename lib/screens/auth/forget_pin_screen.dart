import 'dart:convert';
import 'dart:math'; // Added for random OTP generation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;
  String? _generatedOtp; // Variable to store the local OTP

  static const Color primaryColor = Color(0xFF6239A1);

  // --- STEP 1: SEND OTP ---
  // --- STEP 1: SEND OTP ---
  // --- STEP 1: SEND OTP ---
  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final rawPhone = _phoneController.text.trim();
    final String phone = "91$rawPhone";

    try {
      // 1. Verify if user exists in Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      if (!userDoc.exists) {
        _showSnackBar("Error: No account found with this number.");
        setState(() => _isLoading = false);
        return; // Stops here, doesn't move to Step 1
      }

      // 2. Generate local OTP
      final otp = (100000 + Random().nextInt(900000)).toString();

      // 3. Call Renflair API
      final apiKey = AppConfig.renflairApiKey;
      final countryCode = AppConfig.renflairCountryCode;
      if (apiKey.isEmpty) {
        _showSnackBar('Missing RENFLAIR_API_KEY in .env.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final url = Uri.parse(
        'https://whatsapp.renflair.in/V1.php?API=$apiKey&PHONE=$rawPhone&OTP=$otp&COUNTRY=$countryCode',
      );

      final response = await http.get(url);

      // 4. Handle API Response
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Make the success check much more flexible to catch different API responses
          final statusStr = data['status']?.toString().toLowerCase() ?? '';
          final messageStr = data['message']?.toString().toLowerCase() ?? '';

          final bool success =
              statusStr == 'true' ||
                  statusStr == '1' ||
                  statusStr == 'success' ||
                  messageStr.contains('success') ||
                  messageStr.contains('sent');

          if (success) {
            // SUCCESS! Move to OTP screen
            if (!mounted) return;
            setState(() {
              _currentStep = 1;
              _isLoading = false;
              _generatedOtp = otp;
              _otpController.clear();
            });
            _showSnackBar("OTP sent to WhatsApp!", isError: false); // Green snackbar
          } else {
            // API returned 200 but failed to send the message internally
            final errorMsg = data['message']?.toString() ?? "API Error: Failed to send OTP.";
            _showSnackBar(errorMsg);
            if (mounted) setState(() => _isLoading = false);
          }
        } catch (formatException) {
          // Failsafe in case Renflair doesn't return valid JSON
          print("API Response was not JSON: ${response.body}");
          _showSnackBar("Format Error from API. Check terminal.");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        _showSnackBar("Server Error: Status Code ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {

      _showSnackBar("Exception: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length < 6) {
      _showSnackBar("Please enter full 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    // Verify against locally generated OTP
    final entered = _otpController.text.trim();

    if (_generatedOtp != null && entered == _generatedOtp) {
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
      _showSnackBar("Verified! Create new PIN.", isError: false);
    } else {
      _showSnackBar("Invalid OTP code.");
      _otpController.clear(); // Clear field on wrong attempt
      setState(() => _isLoading = false);
    }
  }

  // --- STEP 3: UPDATE PIN ---
  Future<void> _handleUpdatePin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPinController.text != _confirmPinController.text) {
      _showSnackBar("PINs do not match!");
      return;
    }

    setState(() => _isLoading = true);
    String phone = "91${_phoneController.text.trim()}";

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .update({'pin': _newPinController.text.trim()});

      _showSnackBar("PIN Reset Successful! Please Login.", isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Update Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── TOP PURPLE HEADER ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Reset PIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Secure your account in 3 steps",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── STEP INDICATOR ──
                Row(
                  children: [
                    _buildStepBubble(0, Icons.phone_android_rounded, "Mobile"),
                    _buildStepConnector(0),
                    _buildStepBubble(1, Icons.message_rounded, "OTP"),
                    _buildStepConnector(1),
                    _buildStepBubble(2, Icons.lock_rounded, "New PIN"),
                  ],
                ),
              ],
            ),
          ),

          // ── SCROLLABLE FORM CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STEP 0: ENTER MOBILE ──
                    if (_currentStep == 0) ...[
                      _buildStepTitle(
                        "Enter Registered Mobile",
                        "We'll send an OTP to your WhatsApp",
                      ),
                      const SizedBox(height: 20),
                      _buildLabel("Mobile Number"),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: _inputDecoration(
                          hint: "10-digit number",
                          prefixIcon: Icons.phone_android_rounded,
                          prefixText: "+91  ",
                        ),
                        validator: (val) =>
                        val!.length < 10 ? "Enter valid number" : null,
                      ),
                      const SizedBox(height: 28),
                      _actionButton("Send OTP via WhatsApp", Icons.send_rounded, _handleSendOtp),
                    ],

                    // ── STEP 1: ENTER OTP ──
                    if (_currentStep == 1) ...[
                      _buildStepTitle(
                        "Verify OTP",
                        "Sent to WhatsApp +91 ${_phoneController.text}",
                      ),
                      const SizedBox(height: 20),
                      _buildLabel("6-Digit OTP"),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 10,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        decoration: _inputDecoration(
                          hint: "• • • • • •",
                          prefixIcon: Icons.message_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _currentStep = 0);
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              color: primaryColor, size: 16),
                          label: const Text(
                            "Change Number",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _actionButton("Verify OTP", Icons.verified_rounded, _handleVerifyOtp),
                    ],

                    // ── STEP 2: SET NEW PIN ──
                    if (_currentStep == 2) ...[
                      _buildStepTitle(
                        "Set New PIN",
                        "Choose a strong 6-digit PIN",
                      ),
                      const SizedBox(height: 20),
                      _buildLabel("New PIN"),
                      TextFormField(
                        controller: _newPinController,
                        keyboardType: TextInputType.number,
                        obscureText: !_isNewPinVisible,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _inputDecoration(
                          hint: "Enter 6-digit PIN",
                          prefixIcon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPinVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                    () => _isNewPinVisible = !_isNewPinVisible),
                          ),
                        ),validator: (val) =>
                      val!.length < 6 ? "Must be 6 digits" : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel("Confirm PIN"),
                      TextFormField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        obscureText: !_isConfirmPinVisible,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _inputDecoration(
                          hint: "Re-enter PIN",
                          prefixIcon: Icons.verified_user_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPinVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                            _isConfirmPinVisible = !_isConfirmPinVisible),
                          ),
                        ),
                        validator: (val) =>
                        val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 28),
                      _actionButton("Update PIN", Icons.lock_reset_rounded, _handleUpdatePin),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
  );

  Widget _buildStepBubble(int stepIndex, IconData icon, String label) {
    final bool isActive = _currentStep >= stepIndex;
    final bool isCurrent = _currentStep == stepIndex;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 44 : 38,
          height: isCurrent ? 44 : 38,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
              ),
            ]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive ? primaryColor : Colors.white,
            size: isCurrent ? 22 : 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: _currentStep > stepIndex
              ? Colors.white
              : Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      counterText: "",
      prefixText: prefixText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}