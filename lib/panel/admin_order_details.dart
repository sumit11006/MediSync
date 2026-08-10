
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailsPage extends StatelessWidget {
  final String docId;

  static const Color primaryColor = Color(0xFF6239A1);

  const AdminOrderDetailsPage({super.key, required this.docId});

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return "Recent";
    try {
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy').format((createdAt).toDate());
      } else {
        return createdAt.toString().split(" at")[0];
      }
    } catch (_) {
      return "Recent";
    }
  }
  // --- FULL SCREEN OVERLAY LOGIC ---
  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black, // Makes the background pure black
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Makes the dialog fill the entire screen
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // The Zoomable Image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            ),
            // The Close Icon Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicine_requests')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'Pending';
          bool isVisited = data['isVisited'] == true;
          bool isCancelled = status == 'Cancelled';

          return CustomScrollView(
            slivers: [
              // ── HEADER ──
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['brandName'] ??
                                            data['medicineName'] ??
                                            "Medicine Order",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "ID: ${docId.substring(0, 8).toUpperCase()}  •  ${_formatDate(data['createdAt'])}",
                                        style: TextStyle(
                                          color:
                                          Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _StatusBadge(status: status),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── CANCELLED BANNER ──
              if (isCancelled)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: Colors.red.shade400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order Cancelled",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (data['cancelReason'] != null)
                                Text(
                                  data['cancelReason'],
                                  style: TextStyle(
                                    color: Colors.red.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── ORDER TIMELINE ──
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  "ORDER TRACKING",
                  _buildTimeline(status),
                ),
              ),

              // ── ORDER DETAILS ──
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  "ORDER DETAILS",
                  Column(
                    children: [
                      _buildInfoRow(Icons.medication_outlined,
                          'Medicine',
                          data['brandName'] ??
                              data['medicineName'] ??
                              'N/A'),
                      _buildInfoRow(Icons.science_outlined, 'Composition',
                          data['composition'] ?? 'N/A'),
                      _buildInfoRow(
                          Icons.numbers_outlined,
                          'Quantity',
                          '${data['quantity'] ?? 'N/A'} ${data['unit'] ?? ''}'),
                      _buildInfoRow(Icons.priority_high_rounded, 'Urgency',
                          data['urgency'] ?? 'Normal'),
                    ],
                  ),
                ),
              ),

              // ── CUSTOMER DETAILS ──
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  "CUSTOMER DETAILS",
                  Column(
                    children: [
                      _buildInfoRow(Icons.phone_outlined, 'User Phone',
                          data['userPhone'] ?? 'N/A'),
                      _buildInfoRow(
                          Icons.contact_phone_outlined,
                          'Delivery Contact',
                          data['deliveryContact'] ?? 'N/A'),
                      _buildInfoRow(Icons.location_on_outlined, 'Address',
                          data['deliveryAddress'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),

              // ── PRESCRIPTION ──
              // ── PRESCRIPTION ──
              if (data['prescriptionUrl'] != null &&
                  (data['prescriptionUrl'] as String).isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionCard(
                    "PRESCRIPTION",
                    GestureDetector(
                      onTap: () => _showFullImage(context, data['prescriptionUrl']),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['prescriptionUrl'],
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: primaryColor),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                              ),
                            ),
                          ),
                          // ZOOM ICON OVERLAY
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── TRACKING CONTROLS ──
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  "MANAGE ORDER",
                  _AdminTrackingSection(
                    docId: docId,
                    status: status,
                    isVisited: isVisited,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(String status) {
    int activeStep = 1;
    if (status == 'Request Accepted') activeStep = 2;
    if (status == 'Preparing For Dispatch') activeStep = 3;
    if (status == 'In Transit') activeStep = 4;
    if (status == 'Delivered') activeStep = 5;

    final steps = [
      {"title": "Request Sent", "sub": "Waiting for review"},
      {"title": "Accepted", "sub": "Order approved"},
      {"title": "Preparing", "sub": "Packing order"},
      {"title": "In Transit", "sub": "Out for delivery"},
      {"title": "Delivered", "sub": "Completed"},
    ];

    if (status == 'Cancelled') {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "This order has been cancelled",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      );
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        int i = entry.key;
        bool isActive = activeStep >= i + 1;
        bool isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isActive ? primaryColor : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isActive
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                        : Text(
                      '${i + 1}',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: isActive
                        ? primaryColor.withOpacity(0.3)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(
                      entry.value['title']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color:
                        isActive ? Colors.black87 : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      entry.value['sub']!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryColor.withOpacity(0.6)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
              TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'In Transit':
        return Colors.blue;
      case 'Preparing For Dispatch':
        return Colors.orange;
      case 'Request Accepted':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TRACKING SECTION (logic untouched)
// ─────────────────────────────────────────────

class _AdminTrackingSection extends StatefulWidget {
  final String docId;
  final String status;
  final bool isVisited;

  const _AdminTrackingSection({
    required this.docId,
    required this.status,
    required this.isVisited,
  });

  @override
  State<_AdminTrackingSection> createState() => _AdminTrackingSectionState();
}

class _AdminTrackingSectionState extends State<_AdminTrackingSection> {
  static const Color primaryColor = Color(0xFF6239A1);
  late String _status;
  late bool _isVisited;

  final List<String> statuses = [
    'Pending',
    'Request Accepted',
    'Preparing For Dispatch',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _isVisited = widget.isVisited;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status chips
        const Text(
          'Update Status',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((s) {
            bool isSelected = _status == s;
            return GestureDetector(
              onTap: () async {
                setState(() => _status = s);
                await FirebaseFirestore.instance
                    .collection('medicine_requests')
                    .doc(widget.docId)
                    .update({'status': s});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $s'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Visited toggle
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isVisited
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mark as Visited',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                  Text(
                    _isVisited ? 'Order has been reviewed' : 'Not yet reviewed',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isVisited,
              activeThumbColor: primaryColor,
              onChanged: (val) async {
                setState(() => _isVisited = val);
                await FirebaseFirestore.instance
                    .collection('medicine_requests')
                    .doc(widget.docId)
                    .update({'isVisited': val});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          val ? 'Marked as visited' : 'Marked as not visited'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },),
          ],
        ),
      ],
    );
  }
}
