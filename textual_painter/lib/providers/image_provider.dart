import 'package:flutter/material.dart';
import '../models/image_model.dart';
import '../services/image_service.dart';

class ImageGeneratorProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  String? _generatedImageUrl;
  String? _error;
  bool _isLoading = false;
  List<GeneratedImage> _savedImages = [];
  String _selectedModel = 'sdxl'; // 기본 모델: SDXL

  // 게터
  String? get generatedImageUrl => _generatedImageUrl;
  String? get error => _error;
  bool get isLoading => _isLoading;
  List<GeneratedImage> get savedImages => _savedImages;
  String get selectedModel => _selectedModel;

  // 모델 선택
  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  // 이미지 생성
  Future<void> generateImage(String prompt) async {
    try {
      _setLoading(true);
      _clearError();
      _generatedImageUrl = null;

      // API 호출 (선택된 모델 사용)
      final imageUrl =
          await _imageService.generateImage(prompt, model: _selectedModel);

      _generatedImageUrl = imageUrl;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // 생성된 이미지 저장
  Future<void> saveGeneratedImage(String prompt) async {
    if (_generatedImageUrl == null) return;

    try {
      // 이미지 URL에서 모델 정보 추출
      String model = _selectedModel;
      if (_generatedImageUrl!.contains('?model=')) {
        model = _generatedImageUrl!.split('?model=')[1];
      }

      final newImage = GeneratedImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        imageUrl: _generatedImageUrl!,
        model: model,
        createdAt: DateTime.now(),
      );

      await _imageService.saveImage(newImage);
      await loadSavedImages(); // 저장 후 목록 갱신
    } catch (e) {
      _setError('이미지를 저장하는 중 오류가 발생했습니다: $e');
    }
  }

  // 저장된 이미지 목록 불러오기
  Future<void> loadSavedImages() async {
    try {
      _savedImages = await _imageService.loadImages();
      notifyListeners();
    } catch (e) {
      _setError('저장된 이미지를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 이미지 삭제
  Future<void> deleteImage(String id) async {
    try {
      await _imageService.deleteImage(id);
      _savedImages.removeWhere((image) => image.id == id);
      notifyListeners();
    } catch (e) {
      _setError('이미지를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 이미지 삭제
  Future<void> deleteAllImages() async {
    try {
      await _imageService.deleteAllImages();
      _savedImages.clear();
      notifyListeners();
    } catch (e) {
      _setError('이미지를 초기화하는 중 오류가 발생했습니다: $e');
    }
  }

  // 생성된 이미지 초기화
  void clearGeneratedImage() {
    _generatedImageUrl = null;
    notifyListeners();
  }

  // 이미지를 기기 갤러리에 저장
  Future<bool> saveImageToGallery() async {
    if (_generatedImageUrl == null) return false;
    return await _imageService.saveImageToGallery(_generatedImageUrl!);
  }

  // 오류 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // 오류 초기화
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
