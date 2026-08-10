import 'dart:io';
import 'package:drugbee/screens/pages/select_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestMedicinePage extends StatefulWidget {
  const RequestMedicinePage({super.key});

  @override
  State<RequestMedicinePage> createState() => _RequestMedicinePageState();
}

class _RequestMedicinePageState extends State<RequestMedicinePage> {
  static const Color primaryBlue = Color(0xFF6239A1);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _compController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _phoneController = TextEditingController();

  File? _selectedImage;
  String _selectedUnit = "Tablets";
  String _selectedUrgency = "Medium (1-3 Days)";

  final List<String> _units = ["Tablets", "Strips", "Vials", "Injections", "Syrup (ml)", "Boxes","Bottle","Sachet","Tube","Other"];
  final List<String> _urgencyLevels = [
    "🆘 Emergency (2-5 hours)", "🚨 High (Same Day)", "Medium (1-3 Days)", "Low (Flexible)"
  ];

  @override
  void initState(){
    super.initState();
    _loadUserPhone();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _compController.dispose();
    _qtyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- 0. LOAD PHONE LOGIC ---
  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    // Try to get stored phone
    String? storedPhone = prefs.getString('user_login_phone') ?? prefs.getString('user_phone');

    // If it has 91 prefix (e.g. 919876543210), strip it to show only 10 digits
    if (storedPhone!.startsWith("91") && storedPhone.length > 10) {
      storedPhone = storedPhone.substring(2);
    }
    setState(() {
      _phoneController.text = storedPhone!;
    });
    }

  // --- 1. IMAGE SELECTION LOGIC ---
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 160,
        child: Column(
          children: [
            const Text("Select Image Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceOption(Icons.camera_alt, "Camera", ImageSource.camera),
                _sourceOption(Icons.photo_library, "Gallery", ImageSource.gallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close sheet
        _processImageSelection(source); // Start permission flow
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryBlue.withOpacity(0.1),
            child: Icon(icon, color: primaryBlue),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _processImageSelection(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // Android 13+ uses 'photos', older uses 'storage'
      if (Platform.isAndroid) {
        if (await Permission.photos.request().isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted || status.isLimited) {
      try {
        final pickedFile = await ImagePicker().pickImage(
            source: source,
            imageQuality: 50 // Optimize size
        );
        if (pickedFile != null) {
          setState(() => _selectedImage = File(pickedFile.path));
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } else if (status.isPermanentlyDenied) {
      if(mounted) _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text("We need access to your Camera/Gallery to upload prescriptions. Please enable it in settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Open Settings", style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  // --- 2. NAVIGATION LOGIC ---
  void _navigateToAddress() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a prescription image")),
      );
      return;
    }

    final medicineData = {
      'brandName': _brandController.text,
      'composition': _compController.text,
      'quantity': _qtyController.text,
      'unit': _selectedUnit,
      'urgency': _selectedUrgency,
      // IMPORTANT: Add '91' back here for the database
      'contact': "91${_phoneController.text}",
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSelectionPage(
          medicineData: medicineData,
          prescriptionFile: _selectedImage!,
        ),
      ),
    );
  }

  void _increment() {
    int current = int.tryParse(_qtyController.text) ?? 0;
    setState(() => _qtyController.text = (current + 1).toString());
  }

  void _decrement() {
    int current = int.tryParse(_qtyController.text) ?? 1;
    if (current > 1) {
      setState(() => _qtyController.text = (current - 1).toString());
    }
  }

  // --- 3. UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Request Medicine",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: primaryBlue,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 42),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("MEDICINE DETAILS"),
                    const SizedBox(height: 16),
                    _buildTextField("Brand Name", "e.g. Augmentin 625", _brandController, isRequired: true),
                    const SizedBox(height: 16),
                    _buildTextField("Molecule / Composition", "e.g. Amoxicillin", _compController, isRequired: true),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(width: 180, child: _buildQuantitySelector()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown("Unit", _units, _selectedUnit, (val) => setState(() => _selectedUnit = val!))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("URGENCY LEVEL"),
                    const SizedBox(height: 12),
                    _buildDropdown("Priority", _urgencyLevels, _selectedUrgency, (val) => setState(() => _selectedUrgency = val!)),
                    const SizedBox(height: 24),
                    _buildSectionHeader("PRESCRIPTION / IMAGE"),
                    const SizedBox(height: 12),
                    GestureDetector(onTap: _pickImage, child: _buildUploadBox()),
                    const SizedBox(height: 24),
                    _buildSectionHeader("COMMUNICATION"),
                    const SizedBox(height: 12),
                    _buildTextField(
                      "Contact Number",
                      "10-digit mobile number",
                      _phoneController,
                      isRequired: true,
                      isPhone: true,
                      readOnly: true, // Field is greyed out
                    ),
                    const SizedBox(height: 32),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. WIDGET HELPERS ---
  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.1));
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller,
      {required bool isRequired, bool isPhone = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            if (isRequired) const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : [],

          style: readOnly
              ? const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold) // Grey Text
              : const TextStyle(color: Colors.black),

          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) return 'Field is required';
            if (isPhone && value != null && value.length != 10) return 'Must be 10 digits';
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade50, // Grey Background

            // NO PREFIX
            prefixText: null,
            prefixStyle: null,

            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quantity *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            children: [
              IconButton(onPressed: _decrement, icon: const Icon(Icons.remove_circle_outline, color: primaryBlue, size: 22)),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
              IconButton(onPressed: _increment, icon: const Icon(Icons.add_circle_outline, color: primaryBlue, size: 22)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentVal, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          onSelected: onChanged,
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 300),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          itemBuilder: (context) => items.map((String val) => PopupMenuItem<String>(
            value: val,
            height: 40,
            child: Text(val, style: const TextStyle(fontSize: 14)),
          )).toList(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentVal, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryBlue.withOpacity(0.15))),
      child: _selectedImage != null
          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
          : const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, color: primaryBlue, size: 32),
          SizedBox(height: 8),
          Text("Upload Prescription", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ElevatedButton(
        onPressed: _navigateToAddress,
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CONTINUE TO ADDRESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
