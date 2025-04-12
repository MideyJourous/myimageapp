import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';

import '../models/image_model.dart';

class ImageService {
  final String _baseUrl = 'https://api.thehive.ai/api/v3';
  final String _storageKey = 'generated_images';
  
  // API 키는 환경변수에서 로드
  String get _apiKey => dotenv.env['THEHIVE_API_KEY'] ?? '';
  
  // 번역기 초기화
  final translator = GoogleTranslator();
  
  // 이미지 생성
  Future<String> generateImage(String prompt, {String model = 'sdxl'}) async {
    if (_apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다. 환경 변수를 확인해주세요.');
    }
    
    // 프롬프트를 영어로 번역 (한국어인 경우)
    String translatedPrompt = await _translateToEnglish(prompt);
    
    // TheHive AI API 요청 준비
    final endpoint = model == 'sdxl' 
      ? '$_baseUrl/text-to-image/tasks/sdxl-enhanced'
      : '$_baseUrl/text-to-image/tasks/flux-schnell-enhanced';
    
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    
    Map<String, dynamic> body;
    
    if (model == 'sdxl') {
      // SDXL 모델용 요청 본문
      body = {
        'prompt': translatedPrompt,
        'samples': 1,
        'negative_prompt': 'low quality, bad anatomy, worst quality, low resolution',
        'seed': -1,
        'steps': 20,
        'cfg_scale': 7.5,
      };
    } else {
      // Flux Schnell 모델용 요청 본문
      body = {
        'prompt': translatedPrompt,
        'samples': 1,
        'guidance_scale': 8.0,
        'negative_prompt': 'low quality, bad anatomy, worst quality, low resolution',
      };
    }
    
    try {
      debugPrint('이미지 생성 요청: $endpoint');
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // 응답 구조 확인 및 이미지 URL 추출
        if (responseData['status'] == 'success' && 
            responseData['output'] != null &&
            responseData['output'].isNotEmpty &&
            responseData['output'][0]['result'] != null &&
            responseData['output'][0]['result']['data'] != null) {
          
          // base64 이미지 데이터 추출
          final imageData = responseData['output'][0]['result']['data'];
          
          // 이미지 저장 및 URL 반환
          final imageUrl = await _saveBase64ImageTemp(imageData, model);
          return imageUrl;
        } else {
          throw Exception('이미지 생성 응답이 잘못된 형식입니다: ${response.body}');
        }
      } else if (response.statusCode == 429) {
        throw Exception('API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('이미지 생성 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('이미지 생성 오류: $e');
      throw Exception('이미지 생성 중 오류가 발생했습니다: $e');
    }
  }

  // 프롬프트 영어로 번역 (비영어 텍스트인 경우에만)
  Future<String> _translateToEnglish(String text) async {
    try {
      // 텍스트가 영어인지 확인 (간단한 휴리스틱)
      bool isEnglish = RegExp(r'^[a-zA-Z0-9\s\.,\-_\'"!?():;]*$').hasMatch(text);
      
      if (isEnglish) {
        // 이미 영어라면 번역하지 않음
        return text;
      }
      
      // 영어가 아니라면 번역
      var translated = await translator.translate(text, to: 'en');
      return translated.text;
    } catch (e) {
      debugPrint('번역 오류: $e');
      // 번역에 실패하면 원본 텍스트 반환
      return text;
    }
  }

  // Base64 이미지를 임시 파일로 저장하고 URL 반환
  Future<String> _saveBase64ImageTemp(String base64Image, String model) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      
      // Base64 데이터에서 헤더 제거 (데이터 포맷에 따라 조정 필요)
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',')[1];
      }
      
      // Base64 디코딩 및 파일 저장
      final bytes = base64Decode(cleanBase64);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // 파일 경로를 URL 형식으로 반환
      return 'file://$filePath?model=$model';
    } catch (e) {
      debugPrint('임시 이미지 저장 오류: $e');
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 생성된 이미지 저장
  Future<void> saveImage(GeneratedImage image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImagesJson = prefs.getStringList(_storageKey) ?? [];
      
      // 이미지 정보를 JSON으로 변환하여 저장
      savedImagesJson.add(jsonEncode(image.toJson()));
      await prefs.setStringList(_storageKey, savedImagesJson);
    } catch (e) {
      debugPrint('이미지 저장 오류: $e');
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 저장된 이미지 목록 불러오기
  Future<List<GeneratedImage>> loadImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImagesJson = prefs.getStringList(_storageKey) ?? [];
      
      // JSON 데이터를 GeneratedImage 객체로 변환
      return savedImagesJson.map((jsonStr) {
        return GeneratedImage.fromJson(jsonDecode(jsonStr));
      }).toList();
    } catch (e) {
      debugPrint('이미지 불러오기 오류: $e');
      throw Exception('저장된 이미지를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 삭제
  Future<void> deleteImage(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImagesJson = prefs.getStringList(_storageKey) ?? [];
      
      // ID가 일치하는 이미지 제외하고 다시 저장
      final updatedImagesJson = savedImagesJson.where((jsonStr) {
        final image = GeneratedImage.fromJson(jsonDecode(jsonStr));
        return image.id != id;
      }).toList();
      
      await prefs.setStringList(_storageKey, updatedImagesJson);
    } catch (e) {
      debugPrint('이미지 삭제 오류: $e');
      throw Exception('이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 이미지 삭제
  Future<void> clearAllImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('이미지 초기화 오류: $e');
      throw Exception('모든 이미지를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지를 기기 갤러리에 저장
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      // 파일 URL에서 모델 정보 제거
      String cleanUrl = imageUrl;
      if (imageUrl.contains('?')) {
        cleanUrl = imageUrl.split('?')[0];
      }
      
      // 'file://' 프리픽스 제거
      if (cleanUrl.startsWith('file://')) {
        cleanUrl = cleanUrl.substring(7);
      }
      
      // Dio를 사용해 이미지 다운로드 및 갤러리에 저장
      final response = await Dio().download(
        cleanUrl, 
        '${(await getTemporaryDirectory()).path}/temp_image.png'
      );
      
      if (response.statusCode == 200) {
        final result = await ImageGallerySaver.saveFile(
          '${(await getTemporaryDirectory()).path}/temp_image.png',
          name: 'generated_image_${DateTime.now().millisecondsSinceEpoch}'
        );
        
        return result['isSuccess'] ?? false;
      }
      
      return false;
    } catch (e) {
      debugPrint('갤러리 저장 오류: $e');
      return false;
    }
  }
}