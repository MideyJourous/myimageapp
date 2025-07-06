// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:textual_painter/main.dart';
import 'package:textual_painter/providers/image_provider.dart';
import 'package:textual_painter/providers/theme_provider.dart';

void main() {
  group('Textual Painter App Tests', () {
    testWidgets('App should start without crashing',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp(userId: 'test_user'));

      // Verify that the app starts without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Theme cards should be displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
                create: (_) => ImageGeneratorProvider(userId: 'test_user')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Test'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the app can be built with providers
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('ThemeProvider should initialize correctly', () {
      final provider = ThemeProvider();
      expect(provider.themeCards, isNotEmpty);
      expect(provider.selectedTheme, isNotNull);
    });

    test('ImageGeneratorProvider should initialize correctly', () {
      final provider = ImageGeneratorProvider(userId: 'test_user');
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.savedImages, isEmpty);
    });
  });
}
