import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> pushAdminCredential({
  required String email,
  required String password,
  required String phone,
  required String fullName,
}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final adminData = {
    'email': email,
    'password': password,
    'phone': phone,
    'fullName': fullName,
    'role': 'admin',
    'isAdmin': true,
    'createdAt': FieldValue.serverTimestamp(),
  };
  await db.collection('admin_credential').doc(phone).set(adminData);
  print('Admin credentials pushed to Firestore (admin_credential collection).');
}

Future<void> pushAdminCreds() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  const adminPhone = '911234567890';
  final adminData = {
    'fullName': 'Admin User',
    'phone': adminPhone,
    'pin': '123456',
    'role': 'admin',
    'isAdmin': true,
    'createdAt': FieldValue.serverTimestamp(),
  };

  await db.collection('user_credentials').doc(adminPhone).set(adminData);
  print('Admin credentials pushed to Firestore (user_credentials collection).');
}

void main() async {
  await pushAdminCreds();
}
