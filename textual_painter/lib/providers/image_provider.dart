import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../services/user_service.dart';

class ImageGeneratorProvider extends ChangeNotifier {
  late final ImageService _imageService;
  late final UserService _userService;
  String? _generatedImageUrl;
  String? _error;
  bool _isLoading = false;
  List<GeneratedImage> _savedImages = [];
  bool _isPro = false; // 테스트 버전에서는 무료 사용자로 시작
  int _dailyGenerationCount = 0;
  DateTime? _lastGenerationDate;

  ImageGeneratorProvider({required String userId}) {
    _imageService = ImageService(userId: userId);
    _userService = UserService();
    _initializeProStatus();
  }

  Future<void> _initializeProStatus() async {
    _isPro = await _userService.isProUser();
    notifyListeners();
  }

  String? get generatedImageUrl => _generatedImageUrl;
  String? get error => _error;
  bool get isLoading => _isLoading;
  List<GeneratedImage> get savedImages => _savedImages;
  bool get isPro => _isPro;
  int get dailyGenerationCount => _dailyGenerationCount;

  bool canGenerateImage() {
    // 테스트 모드에서는 제한을 완화
    if (!_isPro && _dailyGenerationCount >= 3) {
      // 무료 사용자: 3개로 증가
      return false;
    }
    if (_isPro && _dailyGenerationCount >= 100) {
      // Pro 사용자: 100개로 증가
      return false;
    }

    final now = DateTime.now();
    if (_lastGenerationDate != null && !_isSameDay(_lastGenerationDate!, now)) {
      _dailyGenerationCount = 0;
    }

    return true;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> generateImage(String prompt) async {
    if (!canGenerateImage()) {
      if (!_isPro) {
        _setError(
            'Free users can only generate 3 images. Please upgrade to Pro!');
      } else {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final remainingHours = tomorrow.difference(now).inHours;
        final remainingMinutes = tomorrow.difference(now).inMinutes % 60;

        _setError(
            'All 100 of your images have been generated! Try again after ${remainingHours}h ${remainingMinutes}m');
      }
      return;
    }

    try {
      _setLoading(true);
      _clearError();
      _generatedImageUrl = null;

      final imageUrl = await _imageService.generateImage(prompt);

      _generatedImageUrl = imageUrl;
      _dailyGenerationCount++;
      _lastGenerationDate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveGeneratedImage(String prompt) async {
    if (_generatedImageUrl == null) return;

    try {
      final newImage = GeneratedImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        imageUrl: _generatedImageUrl!,
        model: 'sdxl',
        createdAt: DateTime.now(),
        userId: '', // userId는 ImageService에서 자동으로 설정됩니다
      );

      await _imageService.saveImage(newImage);
      await loadSavedImages();
    } catch (e) {
      _setError('이미지를 저장하는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> loadSavedImages() async {
    try {
      _savedImages = await _imageService.loadImages();
      notifyListeners();
    } catch (e) {
      _setError('저장된 이미지를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      await _imageService.deleteImage(id);
      _savedImages.removeWhere((image) => image.id == id);
      notifyListeners();
    } catch (e) {
      _setError('이미지를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> deleteAllImages() async {
    try {
      await _imageService.deleteAllImages();
      _savedImages.clear();
      notifyListeners();
    } catch (e) {
      _setError('이미지를 초기화하는 중 오류가 발생했습니다: $e');
    }
  }

  void clearGeneratedImage() {
    _generatedImageUrl = null;
    notifyListeners();
  }

  Future<bool> saveImageToGallery() async {
    if (_generatedImageUrl == null) return false;
    return await _imageService.saveImageToGallery(_generatedImageUrl!);
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> updateProStatus(bool isPro) async {
    _isPro = isPro;
    // UserService와 동기화
    if (isPro) {
      await _userService.toggleProStatus(); // Pro 활성화
    } else {
      // Pro 비활성화를 위해 현재 상태를 토글
      final currentStatus = await _userService.isProUser();
      if (currentStatus) {
        await _userService.toggleProStatus();
      }
    }
    notifyListeners();
  }
}
