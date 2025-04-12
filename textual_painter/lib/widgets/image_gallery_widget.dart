import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../models/image_model.dart';

class ImageGalleryWidget extends StatefulWidget {
  const ImageGalleryWidget({Key? key}) : super(key: key);

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  @override
  void initState() {
    super.initState();

    // 이미지 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ImageGeneratorProvider>(context, listen: false)
          .loadSavedImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<ImageGeneratorProvider>(context);
    final images = imageProvider.savedImages;

    return Column(
      children: [
        // 상단 정보 및 컨트롤
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '저장된 이미지 (${images.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (images.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _confirmClearGallery(context, imageProvider),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('모두 지우기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),

        // 갤러리 내용
        Expanded(
          child: images.isEmpty
              ? _buildEmptyGallery()
              : _buildGalleryGrid(images, imageProvider),
        ),
      ],
    );
  }

  // 빈 갤러리 표시
  Widget _buildEmptyGallery() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 이미지가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이미지를 생성한 후 저장해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 갤러리 그리드 표시
  Widget _buildGalleryGrid(
      List<GeneratedImage> images, ImageGeneratorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return _buildImageCard(image, provider);
        },
      ),
    );
  }

  // 각 이미지 카드 위젯
  Widget _buildImageCard(
      GeneratedImage image, ImageGeneratorProvider provider) {
    return GestureDetector(
      onTap: () => _showImageDetails(context, image),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 이미지
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: image.imageUrl.startsWith('file://')
                          ? Image.file(
                              File(image.imageUrl
                                  .replaceFirst('file://', '')
                                  .split('?')[0]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              image.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // 모델 배지
                  if (image.model != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          image.model == 'sdxl' ? 'SDXL' : 'Flux',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // 삭제 버튼
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          _confirmDeleteImage(context, image.id, provider),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 프롬프트 (간략히)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).cardColor,
                child: Text(
                  image.prompt,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 상세 정보 다이얼로그
  void _showImageDetails(BuildContext context, GeneratedImage image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지
              SizedBox(
                width: double.infinity,
                height: 300,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: image.imageUrl.startsWith('file://')
                      ? Image.file(
                          File(image.imageUrl
                              .replaceFirst('file://', '')
                              .split('?')[0]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.network(
                          image.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // 정보
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 모델 정보
                    if (image.model != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '모델: ${image.model == 'sdxl' ? 'SDXL' : 'Flux Schnell'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 날짜
                    Text(
                      '생성일: ${_formatDate(image.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 12),

                    // 프롬프트
                    const Text(
                      '프롬프트:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        image.prompt,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // 버튼
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final provider = Provider.of<ImageGeneratorProvider>(
                            context,
                            listen: false);
                        final success = await provider.saveImageToGallery();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '이미지가 기기에 저장되었습니다'
                                  : '이미지 저장에 실패했습니다'),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('다운로드'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 이미지 삭제 확인 다이얼로그
  void _confirmDeleteImage(
      BuildContext context, String imageId, ImageGeneratorProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 삭제'),
          content: const Text('이 이미지를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteImage(imageId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('이미지가 삭제되었습니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 갤러리 초기화 확인 다이얼로그
  void _confirmClearGallery(
      BuildContext context, ImageGeneratorProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('갤러리 초기화'),
          content: const Text('모든 이미지를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteAllImages();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('모든 이미지가 삭제되었습니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
