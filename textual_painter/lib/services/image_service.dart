import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

    Map<String, dynamic> body = {
      'prompt': translatedPrompt,
      'samples': 1,
      'negative_prompt':
          'low quality, bad anatomy, worst quality, low resolution',
    };

    if (model == 'sdxl') {
      body.addAll({
        'seed': -1,
        'steps': 20,
        'cfg_scale': 7.5,
      });
    } else {
      body.addAll({
        'guidance_scale': 8.0,
      });
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
        final processedData = _processApiResponse(responseData);

        // 이미지 저장 및 URL 반환
        final imageUrl =
            await _saveBase64ImageTemp(processedData['data'], model);
        return imageUrl;
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
      final isEnglish = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(text) == false;

      if (isEnglish) {
        return text;
      }

      // 영어가 아니라면 번역
      final translation = await translator.translate(text, to: 'en');
      return translation.text;
    } catch (e) {
      debugPrint('번역 오류: $e');
      return text;
    }
  }

  // Base64 이미지를 임시 파일로 저장하고 URL 반환
  Future<String> _saveBase64ImageTemp(String base64Image, String model) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // Base64 데이터에서 헤더 제거
      String cleanBase64 =
          base64Image.replaceAll(RegExp(r'^data:image/\w+;base64,'), '');

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

      // 연결된 이미지 파일도 삭제
      final images = updatedImagesJson
          .map((jsonStr) => GeneratedImage.fromJson(jsonDecode(jsonStr)))
          .toList();
      final deletedImage = images.firstWhere((img) => img.id == id,
          orElse: () => GeneratedImage(
                id: '',
                prompt: '',
                imageUrl: '',
                createdAt: DateTime.now(),
              ));

      if (deletedImage.imageUrl.startsWith('file://')) {
        final filePath =
            deletedImage.imageUrl.replaceFirst('file://', '').split('?')[0];
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('이미지 삭제 오류: $e');
      throw Exception('이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 이미지 삭제
  Future<void> deleteAllImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImagesJson = prefs.getStringList(_storageKey) ?? [];

      // 저장된 모든 이미지 파일 삭제
      for (final jsonStr in savedImagesJson) {
        final image = GeneratedImage.fromJson(jsonDecode(jsonStr));
        if (image.imageUrl.startsWith('file://')) {
          final filePath =
              image.imageUrl.replaceFirst('file://', '').split('?')[0];
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // SharedPreferences에서 이미지 목록 삭제
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('모든 이미지 삭제 오류: $e');
      throw Exception('모든 이미지를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지를 갤러리에 저장
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        final filePath = imageUrl.replaceFirst('file://', '').split('?')[0];
        final file = File(filePath);

        if (await file.exists()) {
          final result = await ImageGallerySaver.saveFile(filePath);
          return result['isSuccess'] ?? false;
        }
      } else if (imageUrl.startsWith('http')) {
        final dio = Dio();
        final response = await dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          name: 'generated_${DateTime.now().millisecondsSinceEpoch}',
        );
        return result['isSuccess'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('갤러리 저장 오류: $e');
      return false;
    }
  }

  // API 응답 처리
  Map<String, dynamic> _processApiResponse(Map<String, dynamic> responseData) {
    if (responseData['status'] != 'success') {
      throw Exception('API 응답 상태가 성공이 아닙니다: ${responseData['status']}');
    }

    if (responseData['output'] == null || responseData['output'].isEmpty) {
      throw Exception('API 응답에 출력 데이터가 없습니다.');
    }

    final output = responseData['output'][0];
    if (output['result'] == null || output['result']['data'] == null) {
      throw Exception('API 응답에 이미지 데이터가 없습니다.');
    }

    return {
      'data': output['result']['data'],
      'metadata': output['result']['metadata'] ?? {},
    };
  }
}
