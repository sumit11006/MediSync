import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drugbee/services/app_config.dart';

class CloudinaryService {
  String get cloudName => AppConfig.cloudinaryCloudName;
  String get uploadPreset => AppConfig.cloudinaryUploadPreset;

  Future<String?> uploadImage(File file, Function(double) onProgress) async {
    final String url = AppConfig.cloudinaryUploadUrl;
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
        "upload_preset": uploadPreset,
      });

      Response response = await Dio().post(
        url,
        data: formData,
        onSendProgress: (sent, total) {

          onProgress(sent / total);
        },
      );

      return response.data['secure_url'];
    } catch (e) {
      return null;
    }
  }
}