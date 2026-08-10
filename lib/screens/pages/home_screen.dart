import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/screens/pages/about_page.dart';
import 'package:drugbee/screens/pages/donate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drugbee/screens/pages/profile_page.dart';
import 'package:drugbee/screens/pages/request_medicine.dart';
import 'package:drugbee/screens/pages/track_request.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _greeting = "Good Morning";
  String? _userPhone;
  String? _chatPhoneNumber;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadUserPhone();
    _loadChatPhoneNumber();
  }

  Future<void> _loadChatPhoneNumber() async {
    try {
      final DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('whatsapp')
          .get();
      if (settingsDoc.exists && settingsDoc.data() != null) {
        final data = settingsDoc.data() as Map<String, dynamic>;
        setState(() {
          _chatPhoneNumber = data['chat_phone_number'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error loading chat phone number: $e");
    }
  }

  void _setGreeting() {
    var hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning ☀️";
      } else if (hour < 17) {
        _greeting = "Good Afternoon 🌤️";
      } else {
        _greeting = "Good Evening 🌙";
      }
    });
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhone =
          prefs.getString('user_login_phone') ?? prefs.getString('user_phone');
    });
  }

  Future<void> _launchWhatsApp() async {
    String phoneNumber = _chatPhoneNumber ?? "919550119666";
    const String message =
        "Hello DrugBee, I need help with a medicine request.";
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );
    try {
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch WhatsApp")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> navPages = [
      _DashboardPage(userPhone: _userPhone, greeting: _greeting),
      const SizedBox(),
      MyRequestsPage(onBack: () => setState(() => _selectedIndex = 0)),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: navPages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 1) {
              _launchWhatsApp();
            } else {
              setState(() => _selectedIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6239A1),
          unselectedItemColor: Colors.grey.shade400,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_sharp),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: "History",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// ───────────────── DASHBOARD PAGE ─────────────────

class _DashboardPage extends StatelessWidget {
  final String? userPhone;
  final String greeting;

  const _DashboardPage({required this.userPhone, required this.greeting});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF6239A1);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── HEADER ──
            Row(
              children: [
                const Icon(
                  Icons.medication_rounded,
                  color: primaryBlue,
                  size: 34,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      userPhone == null
                          ? const Text(
                              "User",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userPhone)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  var data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>;
                                  String fullName = data['fullName'] ?? "User";
                                  String firstName = fullName.split(" ")[0];
                                  return Text(
                                    firstName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                return const Text(
                                  "Loading...",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No new notifications"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: _HeaderCircleIcon(
                    icon: Icons.notifications_rounded,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── BANNER ──
            const PromoBanner(),

            const SizedBox(height: 12),

            // ── TOP COMPANIES ──
            const Text(
              "Top Companies",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPartnerLogo("cipla.png"),
                  _buildPartnerLogo("biocon.png"),
                  _buildPartnerLogo("ipca.png"),
                  _buildPartnerLogo("zydus.png"),
                  _buildPartnerLogo("sun.png"),
                  _buildPartnerLogo("gsk.png"),
                  _buildPartnerLogo("baid.png"),
                ],
              ),
            ),

            const SizedBox(height: 11),

            // ── SERVICES GRID ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.18,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestMedicinePage(),
                    ),
                  ),
                  child: const _ServiceCard(
                    label: "Request\nMedicine",
                    icon: Icons.request_page_rounded,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyRequestsPage(),
                    ),
                  ),
                  child: const _ServiceCard(
                    label: "Track\nRequests",
                    icon: Icons.track_changes_outlined,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DonateSupportPage(),
                    ),
                  ),
                  child: const _ServiceCard(
                    label: " Donate &\n Support",
                    icon: Icons.favorite_outlined,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutDrugBeePage(),
                    ),
                  ),
                  child: const _ServiceCard(
                    label: "About\nDrugBee",
                    icon: Icons.info_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── TRUST BADGES ──
            const Text(
              "Why Trust DrugBee?",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 1,
              childAspectRatio: 2.1,
              children: const [
                _TrustBadge(icon: Icons.verified, label: "Licensed"),
                _TrustBadge(
                  icon: Icons.support_agent_rounded,
                  label: "Free Help",
                ),
                _TrustBadge(icon: Icons.thumb_up_alt, label: "Trusted"),
                _TrustBadge(icon: Icons.verified_user, label: "Genuine"),
                _TrustBadge(icon: Icons.workspace_premium, label: "Certified"),
                _TrustBadge(icon: Icons.description, label: "Quotes"),
              ],
            ),

            const SizedBox(height: 4),

            // ── FOOTER STATS ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFFFFA94D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: "100%", sub: "Privacy"),
                  _StatItem(label: "24x7", sub: "Convenience"),
                  _StatItem(label: "Family", sub: "Care"),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerLogo(String fileName) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Image.asset(
        'assets/$fileName',
        fit: BoxFit.fitHeight,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

// ───────────────── PROMO BANNER (FIXED) ─────────────────

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  static const Color primaryBlue = Color(0xFF6239A1);
  PageController? _pageController;
  int _currentPage = 0;
  static const int _kInfiniteOffset = 10000;
  Timer? _timer;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;


  static const List<Map<String, dynamic>> _defaultBanners = [
    {
      'imageUrl': '',
      'title': 'Find Rare Medicines',
      'subtitle': 'We source hard-to-find medicines from licensed pharmacies',
    },
    {
      'imageUrl': '',
      'title': 'Fast & Safe Delivery',
      'subtitle': 'Doorstep delivery with genuine medicines guaranteed',
    },
    {
      'imageUrl': '',
      'title': 'Donate & Support',
      'subtitle': 'Help someone get the medicine they need today',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      // Fetch ALL banners (no orderBy to avoid missing-index errors)
      final snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .get();

      if (!mounted) return;

      List<Map<String, dynamic>> fetched = [];

      if (snapshot.docs.isNotEmpty) {
        // Only show banners where isActive == true
        final activeDocs = snapshot.docs
            .where((d) => d.data()['isActive'] == true)
            .toList();

        fetched = activeDocs
            .map((doc) => doc.data())
            .toList();
      }

      // If no active banners in Firestore, show built-in defaults
      final finalBanners = fetched.isNotEmpty
          ? fetched
          : List<Map<String, dynamic>>.from(_defaultBanners);

      // Init controller BEFORE setState so build() sees it immediately
      final controller = PageController(initialPage: _kInfiniteOffset);

      if (!mounted) return;
      setState(() {
        _banners = finalBanners;
        _pageController = controller;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      if (!mounted) return;
      final controller = PageController(initialPage: _kInfiniteOffset);
      setState(() {
        _banners = List<Map<String, dynamic>>.from(_defaultBanners);
        _pageController = controller;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _pageController == null) return;
      if (_pageController!.hasClients && _banners.isNotEmpty) {
        final nextPage = _currentPage + 1; // always increment, never reverse
        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── LOADING STATE ──
    if (_isLoading || _pageController == null || _banners.isEmpty) {
      return Container(
        height: 146,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(21),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }


    // ── BANNER ──
    return Column(
      children: [
        Container(
          height: 146,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length * _kInfiniteOffset * 2, // effectively infinite
              onPageChanged: (page) {
                if (mounted) setState(() => _currentPage = page);
              },
              itemBuilder: (context, index) {
                return _buildBannerCard(_banners[index % _banners.length]);
              },
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) {
                final activeDot = _currentPage % _banners.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: activeDot == index ? 22 : 8,
                  decoration: BoxDecoration(
                    color: activeDot == index
                        ? primaryBlue
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final String? imageUrl = banner['imageUrl'] as String?;
    final String title = (banner['title'] ?? '').toString();
    final String subtitle = (banner['subtitle'] ?? '').toString();

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── BACKGROUND IMAGE OR GRADIENT ──
        imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => _gradientBox(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                },
              )
            : _gradientBox(),

        // ── TEXT OVERLAY ──
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryBlue.withOpacity(0.65),
                primaryBlue.withOpacity(0.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientBox() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [primaryBlue, Color(0xFFFFA94D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

// ───────────────── HELPER WIDGETS ─────────────────

class _HeaderCircleIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  const _HeaderCircleIcon({required this.icon, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 26, color: color ?? Colors.black87),
  );
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ServiceCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF6239A1)),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  );
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 24, color: const Color(0xFF6239A1)),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String sub;
  const _StatItem({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
