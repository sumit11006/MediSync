import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderDetailsPage extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailsPage({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  bool isVisited = false;
  String? status;
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
    fetchOrder();
  }

  Future<void> fetchOrder() async {
    final doc = await FirebaseFirestore.instance
        .collection('medicine_requests')
        .doc(widget.orderId)
        .get();
    if (doc.exists) {
      setState(() {
        orderData = doc.data();
        isVisited = orderData?['isVisited'] ?? false;
        status = orderData?['status'] ?? 'Pending';
        isLoading = false;
      });
    }
  }

  Future<void> saveChanges() async {
    if (orderData == null) return;
    await FirebaseFirestore.instance
        .collection('medicine_requests')
        .doc(widget.orderId)
        .update({'isVisited': isVisited, 'status': status});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order updated!')));
    fetchOrder();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (orderData == null) {
      return const Scaffold(body: Center(child: Text('Order not found.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Name: ${orderData?['userName'] ?? 'N/A'}'),
            Text('Phone: ${orderData?['userPhone'] ?? 'N/A'}'),
            Text('Medicine: ${orderData?['composition'] ?? 'N/A'}'),
            Text('Brand: ${orderData?['brandName'] ?? 'N/A'}'),
            Text('Quantity: ${orderData?['quantity'] ?? 'N/A'}'),
            Text('Priority: ${orderData?['priority'] ?? 'N/A'}'),
            Text('Status: $status'),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isVisited,
                  onChanged: (val) => setState(() => isVisited = val ?? false),
                ),
                const Text('Mark as Visited'),
              ],
            ),
            DropdownButton<String>(
              value: status,
              items: statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => status = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
