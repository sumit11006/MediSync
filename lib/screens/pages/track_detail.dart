import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrackDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const TrackDetailsPage({
    super.key,
    required this.docId,
    required this.initialData,
  });

  static const Color primaryBlue = Color(0xFF6239A1);
  static const Color bgLight = Color(0xFFFEF9F5);

  Future<void> _cancelOrder(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();

    // Show Dialog
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Cancel Request?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              const Text(
                "Are you sure you want to cancel? Please tell us why so we can improve.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Text Field
              Container(
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText:
                        "Reason (e.g., Found locally, Ordered wrong item)",
                    hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context), // Close Dialog
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Keep Order",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          reason = "User cancelled without specific reason";
                        }

                        try {
                          await FirebaseFirestore.instance
                              .collection('medicine_requests')
                              .doc(docId)
                              .update({
                                'status': 'Cancelled',
                                'cancellationReason': "User: $reason",
                              });

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Go back to list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Order Cancelled Successfully"),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirm Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- IMAGE ZOOM LOGIC ---
  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicine_requests')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        var data = initialData;

        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        }

        String status = data['status'] ?? 'Pending';
        bool isCancelled = status == 'Cancelled';

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: primaryBlue,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Request #${docId.toUpperCase()}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildBrandedHeader(data, status),

                if (isCancelled)
                  _buildCancelledBanner(data)
                else
                  _buildSectionCard(
                    "TRACKING UPDATES",
                    _buildSmartTimeline(status),
                  ),

                _buildSectionCard(
                  "ORDER SPECIFICATIONS",
                  Column(
                    children: [
                      _buildDataRow(
                        "Medicine",
                        data['brandName'] ?? data['medicineName'] ?? "N/A",
                      ),
                      _buildDataRow(
                        "Composition",
                        data['composition'] ?? "N/A",
                      ),
                      _buildDataRow("Quantity", "${data['quantity'] ?? '1'}"),
                      _buildDataRow("Unit", data['unit'] ?? "Strip"),
                      _buildDataRow("Urgency", data['urgency'] ?? "Normal"),
                      _buildDataRow("Status", status),

                      const Divider(height: 25),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "PRESCRIPTION PREVIEW",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPrescriptionView(context, data['prescriptionUrl']),
                    ],
                  ),
                ),

                if (status == 'Pending')
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _cancelOrder(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel Request",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI WIDGETS ---

  Widget _buildBrandedHeader(Map<String, dynamic> data, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['brandName'] ?? data['medicineName'] ?? "Medicine",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Current Status: $status",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner(Map<String, dynamic> data) {
    String reason = data['cancellationReason'] ?? "Order cancelled.";

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 10),
              const Text(
                "Order Cancelled",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Reason: $reason",
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTimeline(String status) {
    int activeStep = 1;

    if (status == 'Request Accepted') activeStep = 2;
    if (status == 'Preparing For Dispatch') activeStep = 3;
    if (status == 'In Transit') activeStep = 4;
    if (status == 'Delivered') activeStep = 5;

    return Column(
      children: [
        _buildTimelineStep(
          1,
          "Request Sent",
          "Waiting for pharmacist review",
          activeStep >= 1,
          false,
        ),
        _buildTimelineStep(
          2,
          "Request Accepted",
          "Pharmacist has approved order",
          activeStep >= 2,
          false,
        ),
        _buildTimelineStep(
          3,
          "Packing Order",
          "Preparing for dispatch",
          activeStep >= 3,
          false,
        ),
        _buildTimelineStep(
          4,
          "In Transit",
          "Out for delivery",
          activeStep >= 4,
          false,
        ),
        _buildTimelineStep(
          5,
          "Delivered",
          "Package handed over",
          activeStep >= 5,
          true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    int num,
    String title,
    String sub,
    bool active,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: active ? primaryBlue : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: active
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        num.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: active
                    ? primaryBlue.withOpacity(0.5)
                    : Colors.grey.shade100,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  color: active ? Colors.black : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionView(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              "No prescription attached",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.black.withOpacity(0.05),
          ),
          child: const Center(
            child: CircleAvatar(
              backgroundColor: Colors.white70,
              child: Icon(Icons.zoom_in, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
