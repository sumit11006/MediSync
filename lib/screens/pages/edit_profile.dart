import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfilePage extends StatefulWidget {
  final String userPhone;
  final String currentName;
  final String currentEmail;
  final String currentAddress;
  final String currentCity;
  final String currentState;
  final String currentZip;

  const EditProfilePage({
    super.key,
    required this.userPhone,
    required this.currentName,
    required this.currentEmail,
    required this.currentAddress,
    required this.currentCity,
    required this.currentState,
    required this.currentZip,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;

  // State Selection Variable
  String? _selectedState;

  // List of States
  final List<String> _indianStates = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli",
    "Daman and Diu", "Delhi", "Lakshadweep", "Puducherry"
  ];

  bool _isUpdating = false;
  final Color primaryBlue = const Color(0xFF6239A1);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _addressController = TextEditingController(text: widget.currentAddress);
    _cityController = TextEditingController(text: widget.currentCity);
    _zipController = TextEditingController(text: widget.currentZip);

    // Initialize State dropdown with current value
    // (Check if current state exists in list, otherwise default to null or keep value)
    if (_indianStates.contains(widget.currentState)) {
      _selectedState = widget.currentState;
    } else {
      _selectedState = widget.currentState.isNotEmpty ? widget.currentState : null;
      // If the stored state isn't in our list, add it temporarily so it shows up
      if (_selectedState != null && !_indianStates.contains(_selectedState)) {
        _indianStates.add(_selectedState!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a State"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userPhone).update({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState, // Use the dropdown variable
        'zip': _zipController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to strip '91' from phone number for display
    String displayPhone = widget.userPhone;
    if (displayPhone.startsWith("91") && displayPhone.length > 2) {
      displayPhone = displayPhone.substring(2);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Full Name"),
              _buildTextField(_nameController, Icons.person_outline),
              const SizedBox(height: 15),

              _buildLabel("Email Address"),
              _buildTextField(_emailController, Icons.email_outlined),
              const SizedBox(height: 15),

              _buildLabel("Street Address"),
              _buildTextField(_addressController, Icons.location_on_outlined),
              const SizedBox(height: 15),

              // City & State Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("City"),
                        _buildTextField(_cityController, Icons.location_city),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),


                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("State"),
                        _buildDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Zip Code"),
                        TextFormField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          decoration: _inputDecoration().copyWith(prefixIcon: const Icon(Icons.pin_drop_outlined, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Mobile"),
                        TextFormField(
                          initialValue: displayPhone,
                          readOnly: true,
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          decoration: _inputDecoration().copyWith(
                              prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey.shade100,

                              prefixStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildDropdown() {
    return PopupMenuButton<String>(
      constraints: const BoxConstraints(maxHeight: 300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (val) => setState(() => _selectedState = val),
      itemBuilder: (context) {
        return _indianStates.map((String state) {
          return PopupMenuItem<String>(
            value: state,
            child: Text(state),
          );
        }).toList();
      },
      child: Container(
        height: 55, // Matches text field height
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: Colors.grey), // Icon
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedState ?? "Select State",
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedState == null ? Colors.grey[600] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration().copyWith(prefixIcon: Icon(icon, color: Colors.grey)),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6239A1), width: 1.5)),
    );
  }
}
