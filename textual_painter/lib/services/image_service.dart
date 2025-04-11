import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/image_model.dart';

class ImageService {
  static const String _baseUrl = 'http://localhost:5000/api';
  static const String _storageKey = 'generated_images';

  // 이미지 생성 API 호출
  Future<String> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? '이미지 생성에 실패했습니다');
      }
    } catch (e) {
      throw Exception('API 요청 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 저장
  Future<void> saveImage(GeneratedImage image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_storageKey) ?? [];
      
      // 새 이미지 추가
      imagesJson.insert(0, json.encode(image.toJson()));
      
      // 저장
      await prefs.setStringList(_storageKey, imagesJson);
    } catch (e) {
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 저장된 이미지 목록 불러오기
  Future<List<GeneratedImage>> loadImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_storageKey) ?? [];
      
      return imagesJson.map((item) {
        return GeneratedImage.fromJson(json.decode(item));
      }).toList();
    } catch (e) {
      throw Exception('이미지 불러오기 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 삭제
  Future<void> deleteImage(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_storageKey) ?? [];
      
      // 해당 ID의 이미지 필터링
      final updatedList = imagesJson.where((item) {
        final imageData = json.decode(item);
        return imageData['id'] != id;
      }).toList();
      
      // 업데이트된 목록 저장
      await prefs.setStringList(_storageKey, updatedList);
    } catch (e) {
      throw Exception('이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 이미지 삭제
  Future<void> clearAllImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      throw Exception('이미지 초기화 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지를 기기 갤러리에 저장
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      // 임시 디렉토리 경로 가져오기
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/image.jpg';
      
      // Dio를 사용하여 이미지 다운로드
      await Dio().download(
        imageUrl,
        path,
        options: Options(receiveTimeout: Duration(seconds: 30)),
      );
      
      // 다운로드한 이미지를 갤러리에 저장
      final result = await ImageGallerySaver.saveFile(path);
      
      // 임시 파일 삭제
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      
      return result['isSuccess'] ?? false;
    } catch (e) {
      print('갤러리에 이미지 저장 중 오류: $e');
      return false;
    }
  }
}