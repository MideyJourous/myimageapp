import 'package:flutter/material.dart';
import '../models/theme_card_model.dart';

class ThemeProvider extends ChangeNotifier {
  final List<ThemeCardModel> _themeCards = ThemeCards.getThemeCards();
  int _selectedThemeIndex = 0;
  String _currentPrompt = '';

  // 게터
  List<ThemeCardModel> get themeCards => _themeCards;
  int get selectedThemeIndex => _selectedThemeIndex;
  ThemeCardModel get selectedTheme => _themeCards[_selectedThemeIndex];
  String get currentPrompt => _currentPrompt;

  // 테마 선택
  void selectTheme(int index) {
    if (index >= 0 && index < _themeCards.length) {
      _selectedThemeIndex = index;
      _currentPrompt = _themeCards[index].prompt;
      notifyListeners();
    }
  }

  // ID로 테마 선택
  void selectThemeById(String id) {
    final index = _themeCards.indexWhere((theme) => theme.id == id);
    if (index != -1) {
      selectTheme(index);
    }
  }

  // 사용자 정의 프롬프트 설정
  void setCustomPrompt(String prompt) {
    _currentPrompt = prompt;
    notifyListeners();
  }

  // 초기화
  void initialize() {
    _selectedThemeIndex = 0;
    _currentPrompt = _themeCards[0].prompt;
    notifyListeners();
  }
}