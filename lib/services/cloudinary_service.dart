import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dtrxyoc8n';
  static const String _uploadPreset = 'orbit_upload';

  // ── Profile picture upload (existing) ──────────────────────────────────────
  static Future<String?> uploadImage(File imageFile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log('❌ Cloudinary upload blocked: no authenticated user');
      return null;
    }
    if (!imageFile.existsSync()) {
      log('❌ Cloudinary upload blocked: file does not exist');
      return null;
    }
    final fileSize = imageFile.lengthSync();
    if (fileSize > 5 * 1024 * 1024) {
      log('❌ Cloudinary upload blocked: file too large (${fileSize ~/ 1024}KB)');
      return null;
    }

    return _upload(
      imageFile: imageFile,
      folder: 'orbit/profile_pics/${currentUser.uid}',
      uid: currentUser.uid,
    );
  }

  // ── Chat image upload (new) ─────────────────────────────────────────────────
  // Stores under:  orbit/chat_images/<conversationId>/<timestamp>.<ext>
  static Future<String?> uploadChatImage({
    required File imageFile,
    required String conversationId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log('❌ Chat image upload blocked: no authenticated user');
      return null;
    }
    if (!imageFile.existsSync()) {
      log('❌ Chat image upload blocked: file does not exist');
      return null;
    }
    final fileSize = imageFile.lengthSync();
    if (fileSize > 10 * 1024 * 1024) {          // 10 MB limit for chat images
      log('❌ Chat image upload blocked: file too large (${fileSize ~/ 1024}KB)');
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final folder = 'orbit/chat_images/$conversationId/$timestamp';

    return _upload(
      imageFile: imageFile,
      folder: folder,
      uid: currentUser.uid,
    );
  }

  // ── Shared upload helper ────────────────────────────────────────────────────
  static Future<String?> _upload({
    required File imageFile,
    required String folder,
    required String uid,
  }) async {
    try {
      log('📤 Uploading to folder: $folder');

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['context'] = 'firebase_uid=$uid';
      request.fields['folder'] = folder;
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