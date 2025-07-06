import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../providers/image_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/rotating_theme_cards.dart';
import 'pro_ask_mocal.dart';

class ImageGeneratorWidget extends StatefulWidget {
  const ImageGeneratorWidget({Key? key}) : super(key: key);

  @override
  State<ImageGeneratorWidget> createState() => _ImageGeneratorWidgetState();
}

class _ImageGeneratorWidgetState extends State<ImageGeneratorWidget> {
  final _formKey = GlobalKey<FormState>();
  final int _maxPromptLength = 400;
  bool _isSaved = false;
  String _selectedCardPrompt = '';
  String _userInput = '';
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // 지연 설정해서 빌드 컨텍스트 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      // 초기화 처리
      themeProvider.initialize();

      // 첫 번째 카드를 선택하고 프롬프트 저장
      if (themeProvider.themeCards.isNotEmpty) {
        setState(() {
          _selectedCardPrompt = themeProvider.themeCards.first.prompt;
          // 텍스트 입력창은 비워두고 사용자 입력만 받음
          _textController.text = '';
          _userInput = '';

          // 커서를 텍스트 시작으로 이동
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: 0),
          );

          themeProvider.setCustomPrompt(_selectedCardPrompt);
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<ImageGeneratorProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    // ThemeCardModel을 RotatingThemeCards 위젯에서 사용하는 ThemeCard로 변환
    final themeCards = themeProvider.themeCards
        .map((card) => ThemeCard(
              title: card.title,
              imagePath: card.imagePath,
              prompt: card.prompt,
              isPro: card.isPro,
            ))
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 테마 카드 회전 위젯
              Text(
                'Select a theme',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.left,
              ),
              SizedBox(
                height: 530,
                child: RotatingThemeCards(
                  cards: themeCards,
                  onCardSelected: (selectedCard) {
                    setState(() {
                      _selectedCardPrompt = selectedCard.prompt;
                      // 카드 선택 시 텍스트 입력창은 비우고, 사용자 입력만 받음
                      _textController.text = '';
                      _userInput = '';

                      // 커서를 텍스트 시작으로 이동
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: 0),
                      );

                      // ThemeProvider에는 선택된 카드의 프롬프트만 저장
                      themeProvider.setCustomPrompt(selectedCard.prompt);
                    });
                  },
                  isPro: false,
                  onProCardSelected: () {
                    ProAskModal.show(context);
                  },
                ),
              ),

              const SizedBox(height: 4),

              // Prompt Text Field
              TextFormField(
                controller: _textController, // 추가: controller 연결
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Add your description (optional):',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: IconButton(
                    icon: imageProvider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.send),
                    onPressed: imageProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isSaved = false;
                              });
                              // 사용자 입력과 카드 프롬프트를 결합하여 API 요청
                              final combinedPrompt = _userInput.isNotEmpty
                                  ? '$_selectedCardPrompt\n$_userInput'
                                  : _selectedCardPrompt;
                              await imageProvider.generateImage(combinedPrompt);

                              // 무료 사용자가 이미지를 생성한 후 Pro 모달 표시
                              if (!imageProvider.isPro &&
                                  imageProvider.dailyGenerationCount >= 1 &&
                                  context.mounted) {
                                ProAskModal.show(context);
                              }
                            }
                          },
                  ),
                ),
                maxLength: _maxPromptLength,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your image description';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _userInput = value;
                    // 사용자 입력이 있으면 카드 프롬프트와 결합, 없으면 카드 프롬프트만 사용
                    final combinedPrompt = value.isNotEmpty
                        ? '$_selectedCardPrompt\n$value'
                        : _selectedCardPrompt;
                    themeProvider.setCustomPrompt(combinedPrompt);
                  });
                },
              ),

              // Character count display
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 2),
                child: Text(
                  '${_userInput.length}/$_maxPromptLength',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),

              const SizedBox(height: 8),

              // Error Message
              if (imageProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    imageProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Loading Indicator
              if (imageProvider.isLoading)
                Column(
                  children: [
                    SpinKitPulse(
                      color: Theme.of(context).colorScheme.primary,
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Creating your image...\nPlease wait a moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

              // Generated Image
              if (imageProvider.generatedImageUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Generated Image',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageProvider.generatedImageUrl!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image loading error: $error');
                          return Container(
                            height: 300,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Unable to load image'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Save to Gallery Button
                        ElevatedButton.icon(
                          onPressed: _isSaved
                              ? null
                              : () async {
                                  await imageProvider.saveGeneratedImage(
                                      themeProvider.currentPrompt);
                                  setState(() {
                                    _isSaved = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved to gallery'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.save),
                          label: Text(_isSaved ? 'Saved' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSaved ? Colors.grey : Colors.green,
                          ),
                        ),

                        // Download Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success =
                                await imageProvider.saveImageToGallery();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image saved to device'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save image'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        // Clear Button
                        IconButton(
                          onPressed: () {
                            imageProvider.clearGeneratedImage();
                            setState(() {
                              _isSaved = false;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
