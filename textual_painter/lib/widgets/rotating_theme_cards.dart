import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

class ThemeCard {
  final String title;
  final String imagePath;
  final String prompt;
  final bool isPro;

  ThemeCard({
    required this.title,
    required this.imagePath,
    required this.prompt,
    this.isPro = false,
  });
}

class RotatingThemeCards extends StatefulWidget {
  final List<ThemeCard> cards;
  final Function(ThemeCard) onCardSelected;
  final Function() onProCardSelected;
  final double cardWidth;
  final double cardHeight;
  final bool isPro;

  const RotatingThemeCards({
    Key? key,
    required this.cards,
    required this.onCardSelected,
    required this.onProCardSelected,
    required this.isPro,
    this.cardWidth = 288,
    this.cardHeight = 449,
  }) : super(key: key);

  @override
  State<RotatingThemeCards> createState() => _RotatingThemeCardsState();
}

class _RotatingThemeCardsState extends State<RotatingThemeCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 0;
  double _radius = 0.0;
  double _anglePerCard = 0.0;
  Size _containerSize = Size.zero;
  Offset _center = Offset.zero;

  // 드래그 관련 변수
  bool _isDragging = false;
  double _startDragX = 0;
  double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {});
    });

    // 카드 각도 계산
    _anglePerCard = pi / 12; // 15도씩 회전 (변경 가능)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _rotateToNextCard() {
    if (_selectedIndex < widget.cards.length - 1) {
      setState(() {
        _selectedIndex++;
        _animateRotation();
        widget.onCardSelected(widget.cards[_selectedIndex]);
      });
    }
  }

  void _rotateToPreviousCard() {
    if (_selectedIndex > 0) {
      setState(() {
        _selectedIndex--;
        _animateRotation();
        widget.onCardSelected(widget.cards[_selectedIndex]);
      });
    }
  }

  void _rotateToIndex(int index) {
    final selectedCard = widget.cards[index];
    if (selectedCard.isPro && !widget.isPro) {
      widget.onProCardSelected();
      return;
    }

    if (index != _selectedIndex && index >= 0 && index < widget.cards.length) {
      setState(() {
        _selectedIndex = index;
        _animateRotation();
        widget.onCardSelected(widget.cards[_selectedIndex]);
      });
    }
  }

  void _animateRotation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 맞게 반지름 조정
    final screenSize = MediaQuery.of(context).size;
    _containerSize = Size(screenSize.width, screenSize.width * 0.8);
    _center = Offset(_containerSize.width / 2, _containerSize.height * 0.5);
    _radius = _containerSize.width * 0.35;

    return SizedBox(
      width: _containerSize.width,
      height: _containerSize.height,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _isDragging = true;
          _startDragX = details.localPosition.dx;
          _currentRotation = 0.0;
        },
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            final deltaX = details.localPosition.dx - _startDragX;
            _currentRotation += deltaX * 0.01;
            _startDragX = details.localPosition.dx;

            // 일정 임계값을 넘으면 다음 또는 이전 카드로 이동
            if (_currentRotation > 0.3) {
              _rotateToPreviousCard();
              _currentRotation = 0.0;
            } else if (_currentRotation < -0.3) {
              _rotateToNextCard();
              _currentRotation = 0.0;
            }

            setState(() {});
          }
        },
        onHorizontalDragEnd: (details) {
          _isDragging = false;
          _currentRotation = 0.0;
        },
        child: Stack(
          children: [
            ...List.generate(widget.cards.length, (index) {
              if (index == _selectedIndex) return const SizedBox.shrink();

              // 선택된 인덱스와의 거리
              final distanceFromSelected = index - _selectedIndex;

              // 각 카드의 각도 (선택된 카드는 0도, 그 외에는 각도 적용)
              final angle = _anglePerCard * distanceFromSelected;

              // 반원 형태의 위치 계산
              final offset = Offset(
                _radius * sin(angle),
                _radius * (1 - cos(angle).abs()) * 0.7,
              );

              // 중앙 카드와의 거리
              final distance = (index - _selectedIndex).abs();

              // 스케일 계산 (중앙에 가까울수록 크게 표시)
              final scale = distance == 0 ? 1.0 : 0.8;

              return _buildCard(index, angle, offset, scale, distance);
            }),
            // 선택된 카드를 마지막에 렌더링
            _buildCard(_selectedIndex, 0, Offset(_radius * 0, 0), 1.0, 0),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      int index, double angle, Offset offset, double scale, int distance) {
    final card = widget.cards[index];
    final showProOverlay = card.isPro && !widget.isPro;

    return Positioned.fill(
      key: ValueKey('card_$index'),
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(
              _center.dx + offset.dx - (_containerSize.width / 2), offset.dy),
          child: Transform.rotate(
            angle: index == _selectedIndex ? 0 : angle,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.cardWidth,
                height: widget.cardHeight,
                child: GestureDetector(
                  onTap: () => _rotateToIndex(index),
                  child: Card(
                    elevation: index == _selectedIndex ? 8.0 : 4.0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: index == _selectedIndex
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  card.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white70,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Pro 카드이고 사용자가 Pro가 아닌 경우에만 블러 효과와 잠금 아이콘 표시
                                if (showProOverlay)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 5.0, sigmaY: 5.0),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'PRO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      stops: const [0.6, 1.0],
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Text(
                                    card.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3.0,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                // 선택된 카드에 체크 마크 표시 (Pro가 아닌 카드이거나, Pro 카드이면서 사용자가 Pro인 경우)
                                if (index == _selectedIndex && !showProOverlay)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
