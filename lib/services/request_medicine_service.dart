import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  /// Fetches admin config from Firestore and stores in SharedPreferences
  Future<void> fetchAndStoreAdminConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use the correct collection name as per your DB: 'admin_panel_info'
      final snapshot = await _db.collection('admin_panel_info').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data['email'] != null) {
          await prefs.setString('admin_email', data['email']);
        }
        if (data['password'] != null) {
          await prefs.setString('admin_password', data['password']);
        }
        if (data['phone'] != null) {
          await prefs.setString('admin_phone', data['phone']);
        }
        if (data['cloudinary_db_link'] != null) {
          await prefs.setString(
            'cloudinary_db_link',
            data['cloudinary_db_link'],
          );
          await prefs.setString(
            'cloudinary_upload_url',
            data['cloudinary_db_link'],
          );
        }
        if (data['chat_phone_number'] != null) {
          await prefs.setString('chat_phone_number', data['chat_phone_number']);
        }
        if (data['upi_link'] != null) {
          await prefs.setString('upi_link', data['upi_link']);
        }
      }
    } catch (e) {
      print('Error fetching admin config: $e');
    }
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> saveMedicineRequest({
    required String brand,
    required String composition,
    required String quantity,
    required String priority,
    required String imageUrl,
  }) async {
    try {
      // Get userPhone from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? userPhone =
          prefs.getString('user_login_phone') ?? prefs.getString('user_phone');
      if (userPhone == null || userPhone.isEmpty) {
        print("No userPhone found in session. Cannot save request.");
        return false;
      }

      // Use a Firestore transaction to increment the order counter
      final counterRef = _db.collection('counters').doc('medicine_requests');
      int newOrderId = await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        int current = 1000;
        if (snapshot.exists && snapshot.data()!.containsKey('lastOrderId')) {
          current = snapshot['lastOrderId'] as int;
        }
        int next = current + 1;
        transaction.set(counterRef, {'lastOrderId': next});
        return next;
      });

      String orderId = 'DB-$newOrderId';

      await _db.collection('medicine_requests').add({
        'brandName': brand,
        'composition': composition,
        'quantity': quantity,
        'priority': priority,
        'prescriptionUrl': imageUrl,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'orderId': orderId,
        'userPhone': userPhone,
      });
      return true;
    } catch (e) {
      print("Firestore Save Error: $e");
      return false;
    }
  }
}
