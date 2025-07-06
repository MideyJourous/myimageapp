import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_service.dart';

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
