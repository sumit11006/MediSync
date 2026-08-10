import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/screens/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_order_details.dart';
import 'Banner_upload.dart';


class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  static const Color primaryBlue = Color(0xFF6239A1);
  String? _adminPhone;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminPhone = prefs.getString('admin_phone');
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_phone');
    await prefs.remove('is_admin');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text("Logout"),
          ],
        ),
        content: const Text(
            "Are you sure you want to logout from admin panel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("LOGOUT",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      bottomNavigationBar: _buildBottomNav(),
      body: _currentNavIndex == 0
          ? _buildOrdersBody()
          : const BannerUploadPage(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_outlined),
            activeIcon: Icon(Icons.image_rounded),
            label: 'Banners',
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersBody() {
    return CustomScrollView(
      slivers: [
        // ── APP BAR ──
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          backgroundColor: primaryBlue,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6239A1), Color(0xFF8B5CF6)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Admin Panel",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _adminPhone ?? "Administrator",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _showLogoutDialog,
            ),
          ],
        ),

        // ── STATS ROW ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicine_requests')
                  .snapshots(),
              builder: (context, snapshot) {
                int total = 0, pending = 0, delivered = 0;
                if (snapshot.hasData) {
                  total = snapshot.data!.docs.length;
                  pending = snapshot.data!.docs
                      .where((d) => (d['status'] ?? '') == 'Pending')
                      .length;
                  delivered = snapshot.data!.docs
                      .where((d) => (d['status'] ?? '') == 'Delivered')
                      .length;
                }
                return Row(
                  children: [Expanded(
                      child: _buildStatCard(
                          "Total\n$total",
                          Icons.list_alt_rounded,
                          primaryBlue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
                        "Pending\n$pending",
                        Icons.hourglass_top_rounded,
                        Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            "Done\n$delivered",
                            Icons.check_circle_rounded,
                            Colors.green)),
                  ],
                );
              },
            ),
          ),
        ),

        // ── SECTION HEADER ──
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MEDICINE REQUESTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // ── ORDERS LIST ──
        SliverFillRemaining(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('medicine_requests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryBlue));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }
              final orders = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildOrderCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, IconData icon, Color color) {
    final parts = label.split('\n');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            parts.length > 1 ? parts[1] : '',
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          Text(
            parts[0],
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_add,
                size: 60, color: primaryBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Orders Found',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('No medicine requests yet.',
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String docId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    bool isDelivered = status == 'Delivered';
    bool isCancelled = status == 'Cancelled';
    bool isVisited = data['isVisited'] == true;

    Color iconBgColor = primaryBlue.withOpacity(0.1);
    Color iconColor = primaryBlue;
    IconData iconData = Icons.more_horiz;

    if (isDelivered) {
      iconBgColor = Colors.green.withOpacity(0.1);
      iconColor = Colors.green;
      iconData = Icons.check_circle;
    } else if (isCancelled) {
      iconBgColor = Colors.red.withOpacity(0.1);
      iconColor = Colors.red;
      iconData = Icons.cancel;
    } else if (!isVisited) {
      iconBgColor = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
      iconData = Icons.fiber_new;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['brandName'] ?? 'Unknown Medicine',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _getUserName(data['userPhone'] ?? ''),
                        builder: (context, nameSnapshot) {
                          String displayName = "Loading...";
                          if (nameSnapshot.connectionState == ConnectionState.done) {
                            displayName = nameSnapshot.data ?? "Unknown";
                          }

                          return Text(
                            displayName,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontStyle: nameSnapshot.hasData ? FontStyle.normal : FontStyle.italic,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ),_StatusBadge(status: status, color: iconColor),
              ],
            ),
          ),
          const Divider(height: 1, indent: 10, endIndent: 10),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      data['userPhone'] ?? 'N/A',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    // Mark as visited
                    FirebaseFirestore.instance
                        .collection('medicine_requests')
                        .doc(docId)
                        .update({'isVisited': true});

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOrderDetailsPage(
                          docId: docId,
                        ),
                      ),
                    );

                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return "Recent";
    try {
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy').format(createdAt.toDate());
      } else {
        return createdAt.toString().split(" at")[0];
      }
    } catch (_) {
      return "Recent";
    }
  }

  Future<String> _getUserName(String phone) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone) // Assuming 'phone' is the field name in users collection
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['fullName'] ?? 'Unknown User';
      }
      return "User Not Found";
    } catch (e) {
      return "Error loading name";
    }
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

