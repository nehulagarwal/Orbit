import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dtrxyoc8n';
  static const String _uploadPreset = 'orbit_upload';

  static Future<String?> uploadImage(File imageFile) async {
    // ✅ Auth guard — reject if no user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log('❌ Cloudinary upload blocked: no authenticated user');
      return null;
    }

    // ✅ File existence check
    if (!imageFile.existsSync()) {
      log('❌ Cloudinary upload blocked: file does not exist');
      return null;
    }

    // ✅ File size guard (5MB max)
    final fileSize = imageFile.lengthSync();
    if (fileSize > 5 * 1024 * 1024) {
      log('❌ Cloudinary upload blocked: file too large (${fileSize ~/ 1024}KB)');
      return null;
    }

    try {
      log('📤 Uploading image for user: ${currentUser.uid}');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _uploadPreset;

      // ✅ Tag image with Firebase UID — traceable in Cloudinary dashboard
      request.fields['context'] = 'firebase_uid=${currentUser.uid}';

      // ✅ Organise into per-user folder
      request.fields['folder'] = 'orbit/profile_pics/${currentUser.uid}';

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        final url = data['secure_url'] as String?;
        log('✅ Upload success: $url');
        return url;
      } else {
        log('❌ Cloudinary error ${response.statusCode}: $responseData');
        return null;
      }
    } catch (e) {
      log('❌ Cloudinary exception: $e');
      return null;
    }
  }
}