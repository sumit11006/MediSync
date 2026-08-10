import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/screens/pages/track_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyRequestsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const MyRequestsPage({super.key, this.onBack});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  static const Color primaryBlue = Color(0xFF6239A1);
  String? _userPhone;
  bool _isLoadingUser = true;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }


  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    String? phone = prefs.getString('user_login_phone') ?? prefs.getString('user_phone');

    if (mounted) {
      setState(() {
        _userPhone = phone;
        _isLoadingUser = false; // Stop loading regardless of result
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: primaryBlue,
          toolbarHeight: 50,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 42),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context); // Standard back
              }
            },
          ),
          title: const Text(
            "My Requests",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {

    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }


    if (_userPhone == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("User session not found.", style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 5),
            const Text("Please re-login.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    // 3. User Found? Show Lists.
    return TabBarView(
      children: [
        _buildRealRequestList(viewType: "Active"),
        _buildRealRequestList(viewType: "History"),
      ],
    );
  }

  Widget _buildRealRequestList({required String viewType}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicine_requests')
          .where('userPhone', isEqualTo: _userPhone) // Uses correct phone ID
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(viewType);
        }

        var allDocs = snapshot.data!.docs;
        var filteredDocs = allDocs.where((doc) {
          String status = (doc.data() as Map<String, dynamic>)['status'] ?? 'Pending';
          if (viewType == "History") {
            return status == 'Delivered' || status == 'Cancelled';
          } else {
            return status != 'Delivered' && status != 'Cancelled';
          }
        }).toList();

        if (filteredDocs.isEmpty) return _buildEmptyState(viewType);

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];
            var data = doc.data() as Map<String, dynamic>;

            String dateStr = "Recent";
            if (data['createdAt'] != null) {
              try {
                if (data['createdAt'] is Timestamp) {
                  dateStr = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
                } else {
                  dateStr = data['createdAt'].toString().split(" at")[0];
                }
              } catch (e) { dateStr = "Recent"; }
            }

            return _buildOrderCard(doc.id, data, dateStr);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String docId, Map<String, dynamic> data, String date) {
    String status = data['status'] ?? 'Pending';
    bool isDelivered = status == 'Delivered';
    bool isCancelled = status == 'Cancelled';

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
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['brandName'] ?? data['medicineName'] ?? "Medicine",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      // --- FIX 3: SHOW FULL ID ---
                      Text("ID: ${docId.toUpperCase()} | $date",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 10, endIndent: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: status, color: iconColor),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackDetailsPage(
                          docId: docId,
                          initialData: data,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text("View Details",
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14, color: primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FIX 4: BETTER EMPTY STATE ---
  Widget _buildEmptyState(String viewType) {
    String title = viewType == "History" ? "No Past Orders" : "No Active Orders";
    String sub = viewType == "History"
        ? "Your completed orders will show here."
        : "You haven't requested any medicines yet.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: Icon(Icons.assignment_add, size: 50, color: primaryBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}
