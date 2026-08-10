import 'package:drugbee/screens/pages/home_screen.dart';
import 'package:drugbee/screens/pages/privacy_policy.dart';
import 'package:drugbee/screens/pages/tnc.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/services/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedRole;
  bool _isTermsAccepted = false;
  bool _isVerifying = false;
  bool _showOtpField = false;
  bool _isOtpVerified = false;
  String? _generatedOtp;

  final List<String> _roles = [
    'Doctor',
    'Pharmacist / Purchase Incharge',
    'Distributor',
    'Patient',
  ];

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  final Color primaryBlue = const Color(0xFF6239A1);
  final Color successGreen = const Color(0xFF2E7D32);
  String? _selectedState;
  final List<String> _States = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli",
    "Daman and Diu",
    "Delhi",
    "Lakshadweep",
    "Puducherry",
  ];

  // Generates a 6-digit OTP and sends it via Renflair WhatsApp API
  Future<void> _handleVerify() async {
    if (_phoneController.text.length < 10) {
      _showSnackBar("Please enter a valid 10-digit number");
      return;
    }

    setState(() => _isVerifying = true);
    final rawPhone = _phoneController.text.trim();
    final String phone = "91$rawPhone";

    try {
      var userCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();
      if (userCheck.exists) {
        _showSnackBar("Number already registered. Please go to Login.");
        setState(() => _isVerifying = false);
        return;
      }

      // Generate a 6-digit OTP
      final otp = (100000 + Random().nextInt(900000)).toString();

      final apiKey = AppConfig.renflairApiKey;
      final countryCode = AppConfig.renflairCountryCode;
      if (apiKey.isEmpty) {
        setState(() => _isVerifying = false);
        _showSnackBar('Missing RENFLAIR_API_KEY in .env.');
        return;
      }
      final url = Uri.parse(
        'https://whatsapp.renflair.in/V1.php?API=$apiKey&PHONE=$rawPhone&OTP=$otp&COUNTRY=$countryCode',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      // Renflair returns {"status": true/false, ...}
      final statusStr = data['status']?.toString().toLowerCase() ?? '';
      final messageStr = data['message']?.toString().toLowerCase() ?? '';

      final bool success =
          statusStr == 'true' ||
              statusStr == '1' ||
              statusStr == 'success' ||
              messageStr.contains('success') ||
              messageStr.contains('sent');

      if (success) {
        setState(() {
          _isVerifying = false;
          _showOtpField = true;
          _generatedOtp = otp;
          _isOtpVerified = false;
          _otpController.clear();
        });
        _showSnackBar("OTP sent to WhatsApp!", isError: false);
      } else {
        setState(() => _isVerifying = false);
        _showSnackBar(
          data['message']?.toString() ?? "Failed to send OTP. Try again.",
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar("Connection error. Check your internet.");
    }
  }

  Future<void> _verifyAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isTermsAccepted) {
      _showSnackBar("Please agree to the Terms & Conditions.");
      return;
    }
    if (_selectedState == null) {
      _showSnackBar("Please select a State", isError: true);
      return;
    }

    if (!_isOtpVerified) {
      final entered = _otpController.text.trim();
      if (entered.isEmpty) {
        _showSnackBar("Please enter the OTP.");
        return;
      }
      if (_generatedOtp != null && entered != _generatedOtp) {
        _showSnackBar("Invalid OTP. Try again.");
        _otpController.clear();
        return;
      }
      setState(() => _isOtpVerified = true);
    }

    String phone = "91${_phoneController.text.trim()}";

    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(phone).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': phone,
        'role': _selectedRole,
        'issuedId': _credentialController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip': _zipController.text.trim(),
        'pin': _pinController.text.trim(),
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_login_phone', phone);

      _showSnackBar("Registration Successful!", isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnackBar("Error during signup: $e");
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: primaryBlue,
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: "I am"),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val),
                decoration: _inputDecoration("Select Role"),
                validator: (val) => val == null ? "Required" : null,
              ),

              if (_selectedRole == 'Doctor' ||
                  _selectedRole == 'Pharmacist / Purchase Incharge') ...[
                const SizedBox(height: 18),
                _Label(
                  text: _selectedRole == 'Doctor'
                      ? "Registration No."
                      : "Drug License No.",
                ),
                TextFormField(
                  controller: _credentialController,
                  decoration: _inputDecoration("Enter details"),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ],

              const SizedBox(height: 18),
              const _Label(text: "Full Name"),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Enter full name"),
                validator: (val) => val!.isEmpty ? "Name is required" : null,
              ),

              const SizedBox(height: 18),
              const _Label(text: "Mobile No"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _inputDecoration(
                  "10-digit number",
                ).copyWith(prefixText: "+91 "),
                validator: (val) =>
                    val!.length != 10 ? "Exactly 10 digits required" : null,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _showOtpField ? "Resend OTP" : "Send OTP",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              const _Label(text: "Enter OTP"),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _inputDecoration("Enter 6-digit OTP").copyWith(
                  suffixIcon: _isOtpVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  fillColor: _isOtpVerified
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 10),
              const _Label(text: "Email"),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration("Email address"),
                validator: (val) {
                  if (val!.isEmpty) return "Required";
                  if (!val.contains('@')) return "Invalid email (missing @)";
                  return null;
                },
              ),
              const SizedBox(height: 10),

              const _Label(text: "Create Login PIN"),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: _inputDecoration("Enter 6-digit PIN").copyWith(
                  counterText: "", // Hides the small "0/6" counter at bottom
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 22,
                    color: Colors.grey,
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.isEmpty) return "PIN is required";
                  if (val.length != 6) return "PIN must be exactly 6 digits";
                  return null;
                },
              ),

              const SizedBox(height: 5),
              const Text(
                "  * You will use this PIN to login next time.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 15),

              const _Label(text: "Address"),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration("Street/Area"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration("City"),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Label
                        const SizedBox(height: 2),

                        PopupMenuButton<String>(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ), // Limits height so it scrolls
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          onSelected: (val) {
                            setState(() => _selectedState = val);
                          },
                          itemBuilder: (context) {
                            return _States.map((String state) {
                              return PopupMenuItem<String>(
                                value: state,
                                child: Text(state),
                              );
                            }).toList();
                          },
                          // 3. The Button Design (Looks like your other inputs)
                          child: Container(
                            height:
                                55, // Matches the height of your TextFormFields
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedState ?? "Select State",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedState == null
                                          ? Colors.grey[600]
                                          : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              const _Label(text: "Zipcode"),
              TextFormField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _inputDecoration("6-digit zip"),
                validator: (val) =>
                    val!.length != 6 ? "Exactly 6 digits" : null,
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _isTermsAccepted,
                    activeColor: primaryBlue,
                    onChanged: (val) => setState(() => _isTermsAccepted = val!),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "I agree to the ",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsConditionsPage(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTermsAccepted
                        ? primaryBlue
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: _isTermsAccepted
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            _verifyAndRegister();
                          }
                        }
                      : null,
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      color: _isTermsAccepted ? Colors.white : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
