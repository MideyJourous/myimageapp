import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/image_generator_widget.dart';
import '../screens/image_gallery_screen.dart';
import '../widgets/pro_ask_mocal.dart';
import '../providers/image_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showGallery = false;

  void _handleGalleryAccess(BuildContext context) {
    final imageProvider =
        Provider.of<ImageGeneratorProvider>(context, listen: false);
    if (imageProvider.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImageGalleryScreen()),
      );
    } else {
      // 테스트 모드에서는 갤러리 접근 허용
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('테스트 모드'),
          content: const Text(
            '테스트 모드에서는 갤러리에 접근할 수 있습니다.\n'
            '실제 출시 시에는 Pro 구독이 필요합니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ImageGalleryScreen()),
                );
              },
              child: const Text('갤러리 열기'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56, // 기본 AppBar 높이
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Pro 멤버십 아이콘
            Consumer<ImageGeneratorProvider>(
              builder: (context, imageProvider, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: imageProvider.isPro
                        ? Colors.green
                        : const Color(0xFF8A2BE2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        if (imageProvider.isPro) {
                          // Pro 사용자일 때는 상태 토글 가능
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pro 상태'),
                              content: Text(
                                '현재 Pro 상태: ${imageProvider.isPro ? "활성화" : "비활성화"}\n'
                                '테스트 모드에서는 상태를 변경할 수 있습니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('취소'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    imageProvider
                                        .updateProStatus(!imageProvider.isPro);
                                    Navigator.pop(context);
                                  },
                                  child: Text(imageProvider.isPro
                                      ? 'Pro 비활성화'
                                      : 'Pro 활성화'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ProAskModal.show(context);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            imageProvider.isPro
                                ? Icons.check_circle
                                : Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            imageProvider.isPro ? 'PRO' : 'PRO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            // 갤러리 아이콘
            IconButton(
              icon: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
              ),
              onPressed: () => _handleGalleryAccess(context),
            ),
          ],
        ),
      ),
      body: const ImageGeneratorWidget(),
    );
  }
}
