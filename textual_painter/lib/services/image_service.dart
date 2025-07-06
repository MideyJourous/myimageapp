import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // 임시로 주석 처리
// import 'package:firebase_storage/firebase_storage.dart'; // 임시로 주석 처리

class GeneratedImage {
  final String id;
  final String prompt;
  final String imageUrl;
  final String? model;
  final DateTime createdAt;
  final String userId;

  GeneratedImage({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    this.model,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'model': model,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory GeneratedImage.fromMap(Map<String, dynamic> map) {
    return GeneratedImage(
      id: map['id'] as String,
      prompt: map['prompt'] as String,
      imageUrl: map['imageUrl'] as String,
      model: map['model'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as String,
    );
  }

  GeneratedImage copyWith({
    String? id,
    String? prompt,
    String? imageUrl,
    String? model,
    DateTime? createdAt,
    String? userId,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}

class ImageService {
  final String _baseUrl = 'https://api.thehive.ai/api/v3';
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // 임시로 주석 처리
  // final FirebaseStorage _storage = FirebaseStorage.instance; // 임시로 주석 처리
  final String _collectionName = 'generated_images';
  final String _userId;

  // 로컬 저장소도 사용 가능하도록 유지
  final _storageService = StorageService();

  ImageService({required String userId}) : _userId = userId;

  String get _apiKey => dotenv.env['THEHIVE_API_KEY'] ?? '';
  final translator = GoogleTranslator();

  // 이미지 생성
  Future<String> generateImage(String prompt) async {
    try {
      debugPrint('=== Starting Image Generation ===');
      debugPrint('Prompt: $prompt');

      if (_apiKey.isEmpty) {
        throw Exception(
            'API key is not set. Please check your environment variables. Add THEHIVE_API_KEY to your .env file.');
      }

      if (prompt.trim().isEmpty) {
        throw Exception('Prompt cannot be empty');
      }

      String translatedPrompt = await _translateToEnglish(prompt);
      debugPrint('Translated prompt: $translatedPrompt');

      final endpoint = '$_baseUrl/stabilityai/sdxl';
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> body = {
        'input': {
          'prompt': translatedPrompt,
          'negative_prompt':
              'blurry, low quality, bad anatomy, worst quality, low resolution',
          'image_size': {'width': 1024, 'height': 1024},
          'num_inference_steps': 15,
          'guidance_scale': 3.5,
          'num_images': 1,
          'seed': -1,
          'output_format': 'png'
        }
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60)); // 60초 타임아웃 추가

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('output') &&
            responseData['output'] is List &&
            responseData['output'].isNotEmpty &&
            responseData['output'][0].containsKey('url')) {
          return responseData['output'][0]['url'];
        } else {
          throw Exception(
              'API response does not contain image URL. Response: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your THEHIVE_API_KEY.');
      } else if (response.statusCode == 429) {
        throw Exception('API request limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(
            'Image generation failed: ${response.statusCode} ${response.body}');
      }
    } on TimeoutException {
      throw Exception(
          'Request timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Image generation error: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      }
      throw Exception('An error occurred while generating the image: $e');
    }
  }

  Future<String> _translateToEnglish(String text) async {
    try {
      final isEnglish = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(text) == false;
      if (isEnglish) return text;

      final translation = await translator.translate(text, to: 'en');
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  // 이미지 저장 (로컬 저장소만 사용)
  Future<void> saveImage(GeneratedImage image) async {
    try {
      await _storageService.saveGeneratedImage(
        image.copyWith(userId: _userId),
      );
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  // 저장된 이미지 목록 불러오기 (로컬 저장소만 사용)
  Future<List<GeneratedImage>> loadImages() async {
    try {
      final images = await _storageService.getAllImages();
      return images.where((img) => img.userId == _userId).toList();
    } catch (e) {
      throw Exception('Failed to load images: $e');
    }
  }

  // 이미지 삭제 (로컬 저장소만 사용)
  Future<void> deleteImage(String id) async {
    try {
      await _storageService.deleteImage(id);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // 모든 이미지 삭제 (로컬 저장소만 사용)
  Future<void> deleteAllImages() async {
    try {
      await _storageService.clearAllImages();
    } catch (e) {
      throw Exception('Failed to delete all images: $e');
    }
  }

  // 이미지를 기기 갤러리에 저장
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        quality: 100,
      );
      return result['isSuccess'] ?? false;
    } catch (e) {
      debugPrint('Failed to save image to gallery: $e');
      return false;
    }
  }

  // Firebase Storage에 이미지 업로드 (임시로 주석 처리)
  // Future<String> _uploadImageToStorage(String imageUrl) async {
  //   try {
  //     final response = await http.get(Uri.parse(imageUrl));
  //     final file =
  //         File('${(await getTemporaryDirectory()).path}/temp_image.jpg');
  //     await file.writeAsBytes(response.bodyBytes);

  //     final ref = _storage.ref().child(
  //         'images/${_userId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //     await ref.putFile(file);
  //     final downloadUrl = await ref.getDownloadURL();

  //     await file.delete();
  //     return downloadUrl;
  //   } catch (e) {
  //     throw Exception('Failed to upload image to storage: $e');
  //   }
  // }
}

class StorageService {
  static const String _storageKey = 'generated_images';

  // 생성된 이미지 저장
  Future<void> saveGeneratedImage(GeneratedImage image) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getStringList(_storageKey) ?? [];

    // 새 이미지를 리스트의 맨 앞에 추가
    imagesJson.insert(0, jsonEncode(image.toMap()));

    // 저장소에 업데이트된 리스트 저장
    await prefs.setStringList(_storageKey, imagesJson);
  }

  // 저장된 모든 이미지 가져오기
  Future<List<GeneratedImage>> getAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getStringList(_storageKey) ?? [];

    return imagesJson.map((jsonString) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return GeneratedImage.fromMap(json);
    }).toList();
  }

  // 특정 이미지 삭제
  Future<void> deleteImage(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getStringList(_storageKey) ?? [];

    // ID에 해당하는 이미지 필터링
    final filteredImages = imagesJson.where((jsonString) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return json['id'] != id;
    }).toList();

    // 저장소에 업데이트된 리스트 저장
    await prefs.setStringList(_storageKey, filteredImages);
  }

  // 모든 이미지 삭제
  Future<void> clearAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
