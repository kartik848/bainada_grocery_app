import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static const String imgbbApiKey = '1fb4eb559407acc3659daf75b47e14cd';
  static const String uploadUrl = 'https://api.imgbb.com/1/upload';
  static const Duration uploadTimeout = Duration(seconds: 25);

  /// Primary: Upload image bytes directly to Firebase Storage under 'products/' path
  static Future<String?> uploadImageToFirebaseStorage({
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    try {
      final safeName =
          (fileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg')
              .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storageRef =
          FirebaseStorage.instance.ref().child('products/$safeName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask =
          await storageRef.putData(imageBytes, metadata).timeout(uploadTimeout);
      final downloadUrl =
          await uploadTask.ref.getDownloadURL().timeout(uploadTimeout);
      if (downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Firebase Storage upload notice/fallback: $e');
      return null;
    }
  }

  /// Upload image bytes directly to ImgBB and return the public image URL
  static Future<String?> uploadImageToImgBB({
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$uploadUrl?key=$imgbbApiKey');
      final request = http.MultipartRequest('POST', uri);

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename:
            fileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(uploadTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final String imageUrl =
              data['display_url'] ?? data['url'] ?? data['image']?['url'] ?? '';
          if (imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
      }

      // If multipart fails, fallback to Base64 POST
      final base64Image = base64Encode(imageBytes);
      final fallbackResponse = await http.post(
        uri,
        body: {
          'image': base64Image,
          'name':
              fileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}',
        },
      ).timeout(uploadTimeout);

      if (fallbackResponse.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(fallbackResponse.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final String imageUrl =
              data['display_url'] ?? data['url'] ?? data['image']?['url'] ?? '';
          if (imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
      }

      debugPrint(
          'ImgBB Upload Error: Status ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('ImgBB Upload Exception: $e');
      return null;
    }
  }

  /// Pick an image from gallery/camera, convert to Uint8List bytes (CORS-safe on Web),
  /// and upload to Firebase Storage (with ImgBB fallback).
  static Future<String?> pickAndUploadImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Convert picked file to raw bytes for 100% Web CORS & Mobile compatibility
      final Uint8List bytes =
          await pickedFile.readAsBytes().timeout(uploadTimeout);
      final fileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Try Firebase Storage first
      final firebaseUrl = await uploadImageToFirebaseStorage(
        imageBytes: bytes,
        fileName: fileName,
      );

      if (firebaseUrl != null && firebaseUrl.isNotEmpty) {
        return firebaseUrl;
      }

      // 2. Seamlessly fallback to ImgBB if Firebase Storage is unavailable
      return await uploadImageToImgBB(
        imageBytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('Image pick & upload exception: $e');
      return null;
    }
  }
}
