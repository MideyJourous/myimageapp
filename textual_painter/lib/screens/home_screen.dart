import 'package:flutter/material.dart';
import '../widgets/image_generator_widget.dart';
import '../widgets/image_gallery_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('텍스트 이미지 생성기'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.create),
              text: '이미지 생성',
            ),
            Tab(
              icon: Icon(Icons.photo_library),
              text: '갤러리',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 이미지 생성 탭
          ImageGeneratorWidget(),
          
          // 갤러리 탭
          ImageGalleryWidget(),
        ],
      ),
    );
  }
}