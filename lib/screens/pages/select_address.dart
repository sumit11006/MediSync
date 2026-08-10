import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; //
import 'package:drugbee/services/cloudinary_service.dart';
import 'package:drugbee/services/app_config.dart';

class AddressSelectionPage extends StatefulWidget {
  final Map<String, String> medicineData;
  final File prescriptionFile;

  const AddressSelectionPage({
    super.key,
    required this.medicineData,
    required this.prescriptionFile,
  });

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  static const Color primaryBlue = Color(0xFF6239A1);
  static String get _defaultCloudinaryUrl => AppConfig.cloudinaryUploadUrl;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // STATE VARIABLES
  String? _selectedAddressString;
  List<Map<String, String>> _localAddresses = [];
  bool _isFinalizing = false;
  double _uploadProgress = 0;
  String? _cloudinaryUrl;

  @override
  void initState() {
    super.initState();
    _initCloudinaryUrl();
    _loadSavedAddresses();
  }

  // --- INIT CLOUDINARY URL FROM STORAGE OR SET DEFAULT ---
  Future<void> _initCloudinaryUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? url =
        prefs.getString('cloudinary_upload_url') ??
        prefs.getString('cloudinary_db_link');
    setState(() {
      _cloudinaryUrl = url;
    });
  }

  Future<String?> _uploadPrescription() async {
    final prefs = await SharedPreferences.getInstance();
    final configuredUrl =
        _cloudinaryUrl ??
        prefs.getString('cloudinary_upload_url') ??
        prefs.getString('cloudinary_db_link');

    if (configuredUrl != null && configuredUrl.isNotEmpty) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(widget.prescriptionFile.path),
        'upload_preset': AppConfig.cloudinaryUploadPreset,
      });

      final response = await Dio().post(
        configuredUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _uploadProgress = sent / total);
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final secureUrl = data['secure_url']?.toString();
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }
    }

    return _cloudinaryService.uploadImage(widget.prescriptionFile, (progress) {
      if (!mounted) return;
      setState(() => _uploadProgress = progress);
    });
  }

  // --- LOCAL STORAGE LOGIC ---
  // --- UPDATED LOADING LOGIC ---
  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Local Addresses (Your existing code)
    final String? savedData = prefs.getString('user_addresses');
    List<Map<String, String>> tempLocal = [];
    if (savedData != null) {
      tempLocal = List<Map<String, String>>.from(
        json.decode(savedData).map((item) => Map<String, String>.from(item)),
      );
    }

    // 2. Load Firebase Address (NEW CODE)
    String? userPhone =
        prefs.getString('user_login_phone') ?? prefs.getString('user_phone');
    if (userPhone == null || userPhone.isEmpty) {
      if (mounted) {
        setState(() {
          _localAddresses = tempLocal;
        });
      }
      return;
    }

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhone)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // Build the full address string
        String line1 = data['address'] ?? "";
        String city = data['city'] ?? "";
        String state = data['state'] ?? "";
        String zip = data['zip'] ?? data['pincode'] ?? "";

        String fullAddress = [
          line1,
          city,
          state,
        ].where((s) => s.isNotEmpty).join(", ");
        if (zip.isNotEmpty) fullAddress += " - $zip";

        // If a Firebase address exists, add it to the TOP of the list
        if (fullAddress.isNotEmpty) {
          tempLocal.insert(0, {
            "label": "Default (Home)",
            "address": fullAddress,
          });
        }
      }
    } catch (e) {
      print("Error fetching firebase address: $e");
    }

    // 3. Update State
    if (mounted) {
      setState(() {
        _localAddresses = tempLocal;
      });
    }
  }

  Future<void> _saveAddressLocally(Map<String, String> newAddress) async {
    final prefs = await SharedPreferences.getInstance(); //
    _localAddresses.add(newAddress);
    await prefs.setString('user_addresses', json.encode(_localAddresses));
    setState(() {});
  }

  // --- BACKEND LOGIC ---
  String _generateOrderId() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return "DB-${now.year}${now.month}${now.day}-${now.hour}${now.minute}-$random";
  }

  Future<void> _processOrder() async {
    if (_selectedAddressString == null || _selectedAddressString!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a delivery address")),
      );
      return;
    }

    setState(() {
      _isFinalizing = true;
      _uploadProgress = 0;
    });

    try {
      String orderId = _generateOrderId();

      // 1. Upload to Cloudinary
      final prefs = await SharedPreferences.getInstance();
      _cloudinaryUrl ??=
          prefs.getString('cloudinary_upload_url') ??
          prefs.getString('cloudinary_db_link') ??
          _defaultCloudinaryUrl;
      final imageUrl = await _uploadPrescription();
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Prescription upload failed. Please try again.');
      }

      // 2. Save everything to Firestore
      // Use loggedInNumber from SharedPreferences (set at login/signup)
      String? loggedInNumber = prefs.getString('user_login_phone');
      print("-----------------------------------------");
      print("DEBUG: com.drugbee.drugbee Phone Number is: $loggedInNumber");
      print("-----------------------------------------");

      await FirebaseFirestore.instance
          .collection('medicine_requests')
          .doc(orderId)
          .set({
            'orderId': orderId,
            'userPhone': loggedInNumber ?? "NOT_LOGGED_IN", // THE MISSING FIELD
            'brandName': widget.medicineData['brandName'],
            'deliveryAddress': _selectedAddressString,
            'deliveryContact': widget.medicineData['contact'],
            'isVisited': false, //
            'status': 'Pending',
            'prescriptionUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'quantity': widget.medicineData['quantity'],
            'unit': widget.medicineData['unit'],
            'urgency': widget.medicineData['urgency'],
            'composition': widget.medicineData['composition'] ?? '',
          })
          .timeout(const Duration(seconds: 15)); //

      _showSuccessDialog(orderId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  // --- ADD ADDRESS DIALOG ---
  void _showAddAddressDialog() {
    final titleController = TextEditingController();
    final houseController = TextEditingController();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final pincodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 25,
          right: 25,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "New Delivery Address",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _dialogField(titleController, "Label (Home / Office)"),
              _dialogField(houseController, "House / Flat / Floor"),
              _dialogField(streetController, "Street / Landmark"),
              Row(
                children: [
                  Expanded(child: _dialogField(cityController, "City")),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _dialogField(
                      pincodeController,
                      "Pincode",
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (houseController.text.isNotEmpty &&
                        cityController.text.isNotEmpty) {
                      String fullAddress =
                          "${houseController.text}, ${streetController.text}, ${cityController.text} - ${pincodeController.text}";
                      _saveAddressLocally({
                        "label": titleController.text.isEmpty
                            ? "Other"
                            : titleController.text,
                        "address": fullAddress,
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "SAVE ADDRESS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Select Address",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_isFinalizing)
            LinearProgressIndicator(
              value: _uploadProgress,
              color: Colors.green,
            ),

          Expanded(
            child: _localAddresses.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "SAVED ADDRESSES",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ..._localAddresses.map(
                        (addr) => _buildAddressCard(
                          addr['label'] ?? 'Other',
                          addr['address'] ?? '',
                        ),
                      ),
                      _buildAddNewButton(),
                    ],
                  ),
          ),

          _buildBottomAction(),
        ],
      ),
    );
  }

  // --- UI BUILDERS ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "No address added yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please add a delivery address to proceed",
            style: TextStyle(color: Colors.black38),
          ),
          const SizedBox(height: 24),
          _buildAddNewButton(),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String label, String address) {
    bool isSelected = _selectedAddressString == address;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressString = address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              label.toLowerCase().contains('home')
                  ? Icons.home_rounded
                  : Icons.work_rounded,
              color: isSelected ? primaryBlue : Colors.grey,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    address,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: primaryBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return TextButton.icon(
      onPressed: _showAddAddressDialog,
      icon: const Icon(Icons.add_circle_outline_rounded, color: primaryBlue),
      label: const Text(
        "Add New Address",
        style: TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    bool canProceed = _selectedAddressString != null && !_isFinalizing;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: canProceed ? _processOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? primaryBlue : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isFinalizing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "DELIVER TO THIS ADDRESS",
                    style: TextStyle(
                      color: canProceed ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Request Submitted!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Order ID: $orderId",
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "BACK TO HOME",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
