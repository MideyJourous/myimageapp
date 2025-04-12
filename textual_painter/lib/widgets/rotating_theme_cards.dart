import 'dart:math';
import 'package:flutter/material.dart';

class ThemeCard {
  final String title;
  final String imagePath;
  final String prompt;

  ThemeCard({
    required this.title,
    required this.imagePath,
    required this.prompt,
  });
}

class RotatingThemeCards extends StatefulWidget {
  final List<ThemeCard> cards;
  final Function(ThemeCard) onCardSelected;
  final double cardWidth;
  final double cardHeight;

  const RotatingThemeCards({
    Key? key,
    required this.cards,
    required this.onCardSelected,
    this.cardWidth = 294,
    this.cardHeight = 459,
  }) : super(key: key);

  @override
  State<RotatingThemeCards> createState() => _RotatingThemeCardsState();
}

class _RotatingThemeCardsState extends State<RotatingThemeCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _selectedIndex;
  late double _angle;
  late double _radius;
  late Size _containerSize;
  late Offset _center;
  
  // 드래그 관련 변수
  double _startDragX = 0;
  double _currentAngle = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // 화면 크기에 따라 반지름 조정 (나중에 build에서 다시 계산됨)
    _radius = 400;
    _angle = 2 * pi / widget.cards.length;
    _containerSize = Size(800, 600); // 초기값 설정
    _center = Offset(_containerSize.width / 2, _containerSize.height * 0.7);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _rotateToNextCard() {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % widget.cards.length;
      _animateRotation();
    });
  }

  void _rotateToPreviousCard() {
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + widget.cards.length) % widget.cards.length;
      _animateRotation();
    });
  }

  void _rotateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _animateRotation();
      widget.onCardSelected(widget.cards[_selectedIndex]);
    });
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
    _center = Offset(_containerSize.width / 2, _containerSize.height * 0.6);
    _radius = _containerSize.width * 0.4;

    return SizedBox(
      width: _containerSize.width,
      height: _containerSize.height,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _isDragging = true;
          _startDragX = details.localPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            final deltaX = details.localPosition.dx - _startDragX;
            if (deltaX.abs() > 20) {
              _startDragX = details.localPosition.dx;
              if (deltaX > 0) {
                _rotateToPreviousCard();
              } else {
                _rotateToNextCard();
              }
            }
          }
        },
        onHorizontalDragEnd: (details) {
          _isDragging = false;
        },
        child: Stack(
          children: List.generate(widget.cards.length, (index) {
            // 선택된 카드 인덱스를 기준으로 각도 계산
            final angleOffset = (index - _selectedIndex) * (pi / 8);
            
            // 애니메이션 진행에 따라 각도 보간
            final angleValue = _animationController.isDismissed
                ? angleOffset
                : lerpDouble(angleOffset, 0, _animationController.value) ?? angleOffset;
            
            // 카드 위치 계산 (원형 배치)
            final x = _center.dx + _radius * sin(angleValue);
            final y = _center.dy - _radius * (1 - cos(angleValue).abs()) * 0.5;
            
            // 스케일 계산 (중앙에 가까울수록 크게 표시)
            final distance = (index - _selectedIndex).abs();
            final scale = distance == 0 ? 1.0 : 0.85;
            
            // z-index 계산 (중앙에 가까울수록 위에 표시)
            final zIndex = widget.cards.length - distance.toDouble();
            
            // 투명도 계산 (중앙에 가까울수록 선명하게)
            final opacity = 1.0 - (distance * 0.2).clamp(0.0, 0.3);
            
            return Positioned(
              left: x - (widget.cardWidth / 2),
              top: y - (widget.cardHeight / 2),
              width: widget.cardWidth,
              height: widget.cardHeight,
              child: Transform.rotate(
                angle: angleValue,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      onTap: () => _rotateToIndex(index),
                      child: Stack(
                        children: [
                          Card(
                            elevation: index == _selectedIndex ? 8 : 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: index == _selectedIndex
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: Image.asset(
                                      widget.cards[index].imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade800,
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white70,
                                              size: 48,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      color: index == _selectedIndex
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade800,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          widget.cards[index].title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 선택된 카드에 표시할 선택 표시
                          if (index == _selectedIndex)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          })..sort((a, b) {
            // z-index 순서로 정렬 (중앙에 가까운 카드가 위에 표시되도록)
            final indexA = (a as Positioned).child as Transform;
            final indexB = (b as Positioned).child as Transform;
            final scaleA = (indexA.child as Transform).scale;
            final scaleB = (indexB.child as Transform).scale;
            return scaleB!.compareTo(scaleA!);
          }),
        ),
      ),
    );
  }
  
  // 애니메이션 보간을 위한 유틸리티 메서드
  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}