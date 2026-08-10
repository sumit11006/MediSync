import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get renflairApiKey => dotenv.env['RENFLAIR_API_KEY'] ?? '';
  static String get renflairCountryCode =>
      dotenv.env['RENFLAIR_COUNTRY_CODE'] ?? '91';

  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dxmhgkbz2';
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'drugbee';
  static String get cloudinaryBannerUploadPreset =>
      dotenv.env['CLOUDINARY_BANNER_UPLOAD_PRESET'] ?? 'drugbee-banners';

  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';
}