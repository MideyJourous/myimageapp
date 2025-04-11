import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../providers/image_provider.dart';

class ImageGeneratorWidget extends StatefulWidget {
  const ImageGeneratorWidget({Key? key}) : super(key: key);

  @override
  State<ImageGeneratorWidget> createState() => _ImageGeneratorWidgetState();
}

class _ImageGeneratorWidgetState extends State<ImageGeneratorWidget> {
  final TextEditingController _promptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final int _maxPromptLength = 1000;
  bool _isSaved = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<ImageGeneratorProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prompt Text Field
              TextFormField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: '이미지 설명',
                  hintText: '만들고 싶은 이미지를 자세히 설명해주세요...',
                  counterText: '${_promptController.text.length}/$_maxPromptLength',
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLength: _maxPromptLength,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이미지 설명을 입력해주세요';
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              // Error Message
              if (imageProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    imageProvider.error!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),

              const SizedBox(height: 20),

              // Generate Button
              ElevatedButton.icon(
                onPressed: imageProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSaved = false;
                          });

                          await imageProvider.generateImage(_promptController.text);
                        }
                      },
                icon: imageProvider.isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.image),
                label: imageProvider.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('이미지 생성 중...'),
                        ],
                      )
                    : const Text('이미지 생성하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Loading Indicator
              if (imageProvider.isLoading)
                Column(
                  children: const [
                    SpinKitPulse(
                      color: Colors.blue,
                      size: 50.0,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '이미지를 생성하고 있어요...\n잠시만 기다려주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic),
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
                      '생성된 이미지',
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
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text('이미지를 불러올 수 없습니다'),
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
                                      _promptController.text);
                                  setState(() {
                                    _isSaved = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('갤러리에 저장되었습니다'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.save),
                          label: Text(_isSaved ? '저장됨' : '저장하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaved ? Colors.grey : Colors.green,
                          ),
                        ),

                        // Download Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await imageProvider.saveImageToGallery();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('기기에 이미지가 저장되었습니다'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이미지 저장에 실패했습니다'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('다운로드'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
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
                          tooltip: '지우기',
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