import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drugbee/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BannerUploadPage extends StatefulWidget {
  const BannerUploadPage({super.key});

  @override
  State<BannerUploadPage> createState() => _BannerUploadPageState();
}

class _BannerUploadPageState extends State<BannerUploadPage> {
  static const Color primaryBlue = Color(0xFF6239A1);

  // ── YOUR CLOUDINARY CREDENTIALS ──
  String get cloudinaryCloudName => AppConfig.cloudinaryCloudName;
  String get cloudinaryUploadPreset => AppConfig.cloudinaryBannerUploadPreset;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // ── PICK IMAGE & UPLOAD TO CLOUDINARY ──
  Future<void> _pickAndUploadBanner() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final File file = File(image.path);
      final String fileName =
          'banner_${DateTime.now().millisecondsSinceEpoch}';

      // ── UPLOAD TO CLOUDINARY ──
        final uri = Uri.parse(AppConfig.cloudinaryUploadUrl);

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..fields['public_id'] = fileName
        ..fields['folder'] = 'drugbee_banners'
        ..files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String imageUrl = responseData['secure_url'];
        final String publicId = responseData['public_id'];

        // ── SAVE TO FIRESTORE ──
        await FirebaseFirestore.instance.collection('banners').add({
          'imageUrl': imageUrl,
          'publicId': publicId,
          'fileName': fileName,
          'uploadedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        if (mounted) _showSnackBar("Banner uploaded successfully!", isError: false);
      } else {
        if (mounted) _showSnackBar("Cloudinary upload failed. Try again.");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── DELETE BANNER ──
  Future<void> _deleteBanner(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Banner"),
          ],
        ),
        content: const Text(
            "Are you sure you want to delete this banner?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
            const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("DELETE",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('banners')
          .doc(docId)
          .delete();

      if (mounted) _showSnackBar("Banner deleted.", isError: false);
    } catch (e) {
      if (mounted) _showSnackBar("Delete failed: $e");
    }
  }

  // ── TOGGLE ACTIVE ──
  Future<void> _toggleStatus(String docId, bool current) async {
    await FirebaseFirestore.instance
        .collection('banners')
        .doc(docId)
        .update({'isActive': !current});
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── HEADER ──
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: primaryBlue,
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
                            child: const Icon(Icons.image_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Banner Manager",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Manage app banners via Cloudinary",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
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
        ),

        // ── UPLOAD CARD ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadBanner,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? Column(
                      children: [
                        const Icon(Icons.cloud_upload_rounded,
                            color: primaryBlue, size: 42),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36),
                          child: LinearProgressIndicator(
                            backgroundColor:
                            primaryBlue.withOpacity(0.15),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                primaryBlue),
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Uploading to Cloudinary...",
                          style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                        : const Column(
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            color: primaryBlue, size: 46),
                        SizedBox(height: 12),
                        Text(
                          "Tap to Upload Banner",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Select image from gallery",
                          style: TextStyle(
                              fontSize: 13, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'UPLOADED BANNERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // ── BANNERS LIST ──
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('banners')
              .orderBy('uploadedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.image_not_supported_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        Text(
                          "No banners uploaded yet",
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final banners = snapshot.data!.docs;

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final doc = banners[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String imageUrl = data['imageUrl'] ?? '';
                  final bool isActive = data['isActive'] ?? true;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                        // Image Preview
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18)),
                          child: Stack(
                            children: [
                              Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 170,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 170,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: primaryBlue),
                                    ),
                                  );
                                },
                                errorBuilder: (c, e, s) => Container(
                                  height: 170,
                                  color: Colors.grey.shade100,
                                  child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                      size: 40),
                                ),
                              ),
                              if (!isActive)
                                Container(
                                  height: 170,
                                  color: Colors.black.withOpacity(0.45),
                                  child: const Center(
                                    child: Text(
                                      "INACTIVE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Action Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isActive ? "ACTIVE" : "INACTIVE",
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Toggle
                              GestureDetector(
                                onTap: () =>
                                    _toggleStatus(doc.id, isActive),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.08),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Delete
                              GestureDetector(
                                onTap: () => _deleteBanner(doc.id),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                    Colors.red.withOpacity(0.08),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: banners.length,
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
