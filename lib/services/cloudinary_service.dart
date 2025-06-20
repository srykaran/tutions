import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  final String _cloudName = 'dc2f5y3mf';
  final String _uploadPreset = 'sankalp';

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal();

  Future<String> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await _uploadBytes(bytes);
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  Future<String> uploadImageFromBytes(Uint8List imageBytes) async {
    try {
      return await _uploadBytes(imageBytes);
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  Future<String> _uploadBytes(Uint8List bytes) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'sankalp'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Failed to upload image: ${jsonResponse['error']}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
} 