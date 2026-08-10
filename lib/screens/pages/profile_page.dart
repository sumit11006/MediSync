import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/screens/auth/welcome_screen.dart';
import 'package:drugbee/screens/pages/Profile_address.dart';

import 'package:drugbee/screens/pages/help&support.dart';
import 'package:drugbee/screens/pages/privacy_policy.dart';
import 'package:drugbee/screens/pages/edit_profile.dart';
import 'package:drugbee/screens/pages/tnc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Prevents page from reloading on tab switch

  static const Color primaryBlue = Color(0xFF6239A1);

  // --- STATE VARIABLES ---
  String _userName = "Loading...";
  String _userEmail = "";

  // New variables to store address info for the Edit Page
  String _address = "";
  String _city = "";
  String _zip = "";
  String _state = "";
  String _memberSince = "Member since...";
  String _userId = "";

  int _userRating = 0;
  bool _isRated = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? phone =
        prefs.getString('user_login_phone') ?? prefs.getString('user_phone');

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();
      if (doc.exists) {
        var data = doc.data()!;

        String formattedDate = "Unknown";
        if (data['createdAt'] != null) {
          Timestamp t = data['createdAt'];
          formattedDate = DateFormat('MMM yyyy').format(t.toDate());
        }

        if (mounted) {
          setState(() {
            _userName = data['fullName'] ?? "DrugBee User";
            _userEmail = data['email'] ?? "";
            _state = data['state'] ?? "";

            _address = data['address'] ?? "";
            _city = data['city'] ?? "";
            _zip = data['zip'] ?? "";

            _memberSince = "Member since $formattedDate";
            _userId = phone!;
          });
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
    }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  // --- Rate Us Sheet Logic ---
  void _showRateUsSheet(BuildContext context) {
    setState(() {
      _userRating = 0;
      _isRated = false;
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isRated
                  ? _buildSuccessView()
                  : _buildRatingView(setSheetState),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingView(StateSetter setSheetState) {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.stars_rounded, color: primaryBlue, size: 60),
        const SizedBox(height: 20),
        const Text(
          "Enjoying DrugBee?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Tap a star to give your feedback.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setSheetState(() => _userRating = index + 1);
              },
              icon: Icon(
                _userRating > index
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 45,
                color: primaryBlue,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _userRating == 0
                ? null
                : () {
                    setSheetState(() => _isRated = true);
                    Future.delayed(
                      const Duration(seconds: 2),
                      () => Navigator.pop(context),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
              "SUBMIT FEEDBACK",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
        const SizedBox(height: 20),
        const Text(
          "Thank You!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          "You gave us $_userRating stars.",
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 4.5,
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Stack(
                children: [
                  // --- EDIT ICON ---
                  Positioned(
                    top: 50,
                    right: 15,
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_square,
                        color: Colors.white,
                        size: 23,
                      ),
                      onPressed: () async {
                        // Navigate to Edit Page with ALL current details
                        final bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              userPhone: _userId,
                              currentName: _userName,
                              currentEmail: _userEmail,
                              currentAddress: _address,
                              currentCity: _city,
                              currentZip: _zip,
                              currentState: _state,
                            ),
                          ),
                        );

                        // If user saved changes, refresh this page
                        if (result == true) {
                          _loadUserProfile();
                        }
                      },
                    ),
                  ),

                  // --- PROFILE INFO ---
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 31,
                            backgroundColor: Color(0xFFF0F0F0),
                            child: Icon(
                              Icons.person_rounded,
                              size: 37,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),

                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          _memberSince,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),

                        _buildIdBadge(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- MENU ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupLabel("HEALTH & LOGISTICS"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileAddressPage(),
                      ),
                    ),
                    child: _buildSettingTile(
                      Icons.location_on_outlined,
                      "Delivery Addresses",
                      "Manage home, work & hospital locations",
                    ),
                  ),

                  _buildGroupLabel("SUPPORT & FEEDBACK"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportPage(),
                      ),
                    ),
                    child: _buildSettingTile(
                      Icons.help_outline_rounded,
                      "Help & Support",
                      "FAQs and direct contact",
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showRateUsSheet(context),
                    child: _buildSettingTile(
                      Icons.star_outline_rounded,
                      "Rate Us",
                      "Tell us your experience",
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildGroupLabel("LEGAL"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsPage(),
                      ),
                    ),
                    child: _buildSettingTile(
                      Icons.description_outlined,
                      "Terms & Conditions",
                      "Our service agreement",
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    ),
                    child: _buildSettingTile(
                      Icons.shield_outlined,
                      "Privacy Policy",
                      "How we protect your data",
                    ),
                  ),

                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: _buildLogoutButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdBadge(BuildContext context) {
    if (_userId.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: _userId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ID Copied")));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ID: $_userId",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded, color: Colors.white54, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.grey,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildSettingTile(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryBlue, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Colors.black12,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              "Logout Account",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
