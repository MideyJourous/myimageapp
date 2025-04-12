class ThemeCardModel {
  final String id;
  final String title;
  final String imagePath;
  final String prompt;

  ThemeCardModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.prompt,
  });
}

// 미리 정의된 테마 카드 목록 (앱에서 사용할 준비된 테마들)
class ThemeCards {
  static List<ThemeCardModel> getThemeCards() {
    return [
      ThemeCardModel(
        id: 'nature',
        title: '자연',
        imagePath: 'assets/themes/nature.jpg',
        prompt: '푸른 숲과 맑은 호수가 있는 평화로운 자연 풍경',
      ),
      ThemeCardModel(
        id: 'fantasy',
        title: '판타지',
        imagePath: 'assets/themes/fantasy.jpg',
        prompt: '마법과 신비로운 생물들이 있는 판타지 세계',
      ),
      ThemeCardModel(
        id: 'abstract',
        title: '추상',
        imagePath: 'assets/themes/abstract.jpg',
        prompt: '화려한 색상과 흐르는 듯한 형태의 추상적 이미지',
      ),
      ThemeCardModel(
        id: 'space',
        title: '우주',
        imagePath: 'assets/themes/space.jpg',
        prompt: '별들과 은하가 빛나는 심오한 우주 풍경',
      ),
      ThemeCardModel(
        id: 'city',
        title: '도시',
        imagePath: 'assets/themes/city.jpg',
        prompt: '밤에 빛나는 현대적인 도시의 스카이라인',
      ),
      ThemeCardModel(
        id: 'portrait',
        title: '인물',
        imagePath: 'assets/themes/portrait.jpg',
        prompt: '자연광으로 촬영된 정교한 표정을 가진 인물 사진',
      ),
      ThemeCardModel(
        id: 'food',
        title: '음식',
        imagePath: 'assets/themes/food.jpg',
        prompt: '완벽하게 플레이팅된 맛있어 보이는 음식',
      ),
      ThemeCardModel(
        id: 'animal',
        title: '동물',
        imagePath: 'assets/themes/animal.jpg',
        prompt: '자연 서식지에 있는 멋진 야생 동물',
      ),
      ThemeCardModel(
        id: 'ocean',
        title: '바다',
        imagePath: 'assets/themes/ocean.jpg',
        prompt: '푸른 바다와 흰 모래가 있는 평화로운 열대 해변',
      ),
      ThemeCardModel(
        id: 'art',
        title: '예술',
        imagePath: 'assets/themes/art.jpg',
        prompt: '화려한 색상과 질감이 있는 현대 미술 작품',
      ),
    ];
  }
}