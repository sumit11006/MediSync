import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/screens/pages/edit_profile.dart'; // Ensure this import matches your project
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAddressPage extends StatefulWidget {
  const ProfileAddressPage({super.key});

  @override
  State<ProfileAddressPage> createState() => _ProfileAddressPageState();
}

class _ProfileAddressPageState extends State<ProfileAddressPage> {
  static const Color primaryBlue = Color(0xFF6239A1);

  Map<String, String>? _firebaseAddress;
  Map<String, dynamic>? _fullUserData; // Store full data to pass to Edit Profile
  List<Map<String, String>> _localAddresses = [];

  bool _isLoading = true;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadAllAddresses();
  }

  Future<void> _loadAllAddresses() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get Phone
    _userPhone = prefs.getString('user_login_phone') ?? prefs.getString('user_phone');

    // 2. Load Local Addresses
    final String? localData = prefs.getString('user_addresses');
    if (localData != null) {
      _localAddresses = List<Map<String, String>>.from(
        json.decode(localData).map((item) => Map<String, String>.from(item)),
      );
    }

    // 3. Load Firebase Address
    if (_userPhone != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(_userPhone).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          _fullUserData = data; // SAVE FULL DATA FOR EDIT PAGE

          String line1 = data['address'] ?? "";
          String city = data['city'] ?? "";
          String state = data['state'] ?? "";
          String zip = data['zip'] ?? data['pincode'] ?? "";

          String fullAddress = [line1, city, state].where((s) => s.isNotEmpty).join(", ");
          if (zip.isNotEmpty) fullAddress += " - $zip";

          if (fullAddress.isNotEmpty) {
            _firebaseAddress = {
              "label": "Home",
              "address": fullAddress,
              "isDefault": "true"
            };
          }
        }
      } catch (e) {
        debugPrint("Error loading firebase address: $e");
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- SAVE LOCAL ---
  Future<void> _saveLocalAddress(List<Map<String, String>> updatedList) async {
    setState(() => _localAddresses = updatedList);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_addresses', json.encode(_localAddresses));
  }

  // --- EDIT DEFAULT (Navigates to EditProfilePage) ---
  Future<void> _editDefaultAddress() async {
    if (_fullUserData == null || _userPhone == null) return;

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userPhone: _userPhone!,
          currentName: _fullUserData!['fullName'] ?? "",
          currentEmail: _fullUserData!['email'] ?? "",
          currentAddress: _fullUserData!['address'] ?? "",
          currentCity: _fullUserData!['city'] ?? "",
          currentState: _fullUserData!['state'] ?? "",
          currentZip: _fullUserData!['zip'] ?? _fullUserData!['pincode'] ?? "",
        ),
      ),
    );

    // If changes were made, reload
    if (result == true) {
      setState(() => _isLoading = true);
      _loadAllAddresses();
    }
  }

  // --- EDIT LOCAL (Opens Sheet) ---
  void _editLocalAddress(int index) {
    Map<String, String> currentAddr = _localAddresses[index];
    final titleController = TextEditingController(text: currentAddr['label']);
    final addressController = TextEditingController(text: currentAddr['address']);

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
          top: 20, left: 25, right: 25,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _dialogField(titleController, "Label"),
              _dialogField(addressController, "Full Address"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    if (addressController.text.isNotEmpty) {
                      List<Map<String, String>> tempList = List.from(_localAddresses);
                      tempList[index] = {
                        "label": titleController.text.isEmpty ? "Other" : titleController.text,
                        "address": addressController.text,
                      };
                      _saveLocalAddress(tempList);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address updated"),backgroundColor: Colors.green, behavior:SnackBarBehavior.floating,));
                    }
                  },
                  child: const Text("UPDATE ADDRESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text("My Addresses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: _showAddAddressSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD NEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_firebaseAddress != null) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text("DEFAULT ADDRESS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          _buildAddressTile(_firebaseAddress!, -1, isFirebase: true),
          const SizedBox(height: 25),
        ],
        if (_localAddresses.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text("SAVED ADDRESSES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          ...List.generate(_localAddresses.length, (index) {
            return _buildAddressTile(_localAddresses[index], index, isFirebase: false);
          }),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAddressTile(Map<String, String> addr, int index, {required bool isFirebase}) {
    String label = addr['label'] ?? "Other";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: isFirebase ? Border.all(color: primaryBlue.withOpacity(0.3), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isFirebase ? primaryBlue : primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            label.toLowerCase().contains('home') ? Icons.home_rounded : Icons.work_rounded,
            color: isFirebase ? Colors.white : primaryBlue,
          ),
        ),
        title: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isFirebase) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(5)),
                child: Text("default", style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(addr['address'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        // --- CHANGED: Edit Icon + Delete Icon (Row) ---
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EDIT BUTTON
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              onPressed: () => isFirebase ? _editDefaultAddress() : _editLocalAddress(index),
            ),
            //
            if (!isFirebase)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirm(index),
              ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Address?"),
        content: const Text("This will remove the address from your saved list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              List<Map<String, String>> tempList = List.from(_localAddresses);
              tempList.removeAt(index);
              _saveLocalAddress(tempList);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressSheet() {
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
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(top: 20, left: 25, right: 25, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Delivery Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _dialogField(titleController, "Label (e.g. Office)"),
              _dialogField(houseController, "House / Flat / Floor"),
              _dialogField(streetController, "Street / Landmark"),
              Row(
                children: [
                  Expanded(child: _dialogField(cityController, "City")),
                  const SizedBox(width: 15),
                  Expanded(child: _dialogField(pincodeController, "Pincode", isNumber: true)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    if (houseController.text.isNotEmpty && cityController.text.isNotEmpty) {
                      String fullAddress = "${houseController.text}, ${streetController.text}, ${cityController.text} - ${pincodeController.text}";
                      List<Map<String, String>> tempList = List.from(_localAddresses);
                      tempList.add({"label": titleController.text.isEmpty ? "Other" : titleController.text, "address": fullAddress});
                      _saveLocalAddress(tempList);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("SAVE ADDRESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
