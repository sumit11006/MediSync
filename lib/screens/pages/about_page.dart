import 'package:flutter/material.dart';

class AboutDrugBeePage extends StatelessWidget {
  const AboutDrugBeePage({super.key});

  static const Color primaryBlue = Color(0xFF6239A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "About DrugBee",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ───── HERO SECTION ─────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: primaryBlue,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "DrugBee",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Version 1.0.2",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Medicine Sourcing & Fulfillment Platform",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ───── WHAT IS DRUGBEE ─────
                  _buildSectionCard(
                    icon: Icons.info_outline_rounded,
                    title: "What is DrugBee?",
                    content:
                    "DrugBee is a medicine sourcing and fulfillment platform that helps you find rare or hard-to-find medicines. We work exclusively with licensed pharmacies and authorized distributors to ensure you receive safe, genuine, and verified medicines.",
                  ),

                  const SizedBox(height: 16),

                  // ───── HOW IT WORKS ─────
                  _buildCardWithRows(
                    icon: Icons.auto_awesome_rounded,
                    title: "How It Works",
                    rows: [
                      _FeatureItem(
                        Icons.camera_alt_outlined,
                        "Search by Photo or Name",
                        "Upload a medicine photo or type the name to start your search instantly.",
                      ),
                      _FeatureItem(
                        Icons.verified_rounded,
                        "Licensed Partners Only",
                        "We source medicines exclusively from licensed pharmacies and authorized distributors.",
                      ),
                      _FeatureItem(
                        Icons.local_shipping_outlined,
                        "Doorstep Delivery",
                        "Delivery is handled by DrugBee logistics or our trusted partner pharmacies.",
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ───── IMPORTANT NOTICE ─────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFF9A825), size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "DrugBee does not provide medical advice. Always consult a qualified doctor before using any medicine. A valid prescription may be required for certain medicines as per Indian law.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6D4C00),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ───── SAFETY & RETURNS ─────
                  _buildCardWithRows(
                    icon: Icons.shield_outlined,
                    title: "Safety & Returns",
                    rows: [
                      _FeatureItem(
                        Icons.check_circle_outline_rounded,
                        "Verified Medicines",
                        "All medicines are sourced from licensed pharmacies. Always check packaging and expiry before use.",
                      ),
                      _FeatureItem(
                        Icons.assignment_return_outlined,
                        "Return Policy",
                        "Medicines once delivered are non-returnable except for wrong, damaged, or expired products reported within 24–48 hours.",
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ───── CONTACT SECTION ─────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_support_rounded,
                                color: primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Contact & Support",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildContactRow(
                            Icons.email_outlined, "support@drugbee.com"),
                        const SizedBox(height: 10),
                        _buildContactRow(
                            Icons.language_rounded, "www.drugbee.com"),
                        const SizedBox(height: 10),
                        _buildContactRow(
                            Icons.gavel_rounded, "Applicable under Indian Law"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ───── FOOTER ─────
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Made with ❤️ for Healthcare",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "© 2025 DrugBee. All rights reserved.",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),const SizedBox(height: 4),
                        Text(
                          "User data is protected using standard security practices.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWithRows({
    required IconData icon,
    required String title,
    required List<_FeatureItem> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...rows.map((item) => _buildFeatureRow(
            item.icon,
            item.title,
            item.desc,
            isLast: item.isLast,
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      IconData icon,
      String title,
      String desc, {
        bool isLast = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  final bool isLast;

  const _FeatureItem(this.icon, this.title, this.desc, {this.isLast = false});
}
