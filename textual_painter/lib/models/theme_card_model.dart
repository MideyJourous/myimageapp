class ThemeCardModel {
  final String id;
  final String title;
  final String imagePath;
  final String prompt;
  final bool isPro;

  ThemeCardModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.prompt,
    this.isPro = false,
  });
}

// 미리 정의된 테마 카드 목록 (앱에서 사용할 준비된 테마들)
class ThemeCards {
  static List<ThemeCardModel> getThemeCards() {
    return [
      ThemeCardModel(
        id: 'glorious',
        title: 'Glorious',
        imagePath: 'assets/themes/glorious.jpg',
        prompt:
            'inspired by the techniques of (((Joseph Christian Leyendecker))), featuring (bold brushwork) illustration that captures natural skin tone colors. academic drawing study of a Nordic auburn athletic human head neck. drawn in soft skin colors and shades on an overall ((grey cardboard)) as background. focus on capturing intricate details such as the play of light on skin. Use dramatic lighting to create depth and contrast, back lighting, enhancing the three-dimensional quality of the subject. The overall piece should reflect the craftsmanship and artistic innovation characteristic of Leyendecker\'s style. ',
        isPro: false,
      ),
      ThemeCardModel(
        id: 'modern_black',
        title: 'Modern Black',
        imagePath: 'assets/themes/modern_black.jpg',
        prompt:
            'black and white photography in style by Bruce Davidson, fashion editorial, long exposure photography through artistic lens, highres, realistic photo, professional photography, cinematic angle, dynamic light back shining, bokeh,',
        isPro: false,
      ),
      ThemeCardModel(
        id: 'afternoon',
        title: 'Afternoon',
        imagePath: 'assets/themes/afternoon.jpg',
        prompt:
            'The image quality is grainy, with a slight blur softening the details. The lighting is dim, casting shadows that obscure object\'s features. The old camera struggles to focus, giving the photo an authentic, unpolished feel. the vibe of the photos is raw, everyday atmosphere of the scene.',
        isPro: false,
      ),
      ThemeCardModel(
        id: 'butterfly',
        title: 'Butterfly',
        imagePath: 'assets/themes/butterfly.jpg',
        prompt:
            'in the style of pop surrealism, by contemporary illustrator, light pink background, detailed facial features, pastel colors, colorful manga cover art, magic, ethereal creatures, neo pop',
        isPro: true,
      ),
      ThemeCardModel(
        id: 'goldenage',
        title: 'Golden Age',
        imagePath: 'assets/themes/golden_age.jpg',
        prompt:
            'Art Deco, 1920s style, roaring twenties era, richly detailed portrait inspired by the techniques of (((Joseph Christian Leyendecker))), featuring dynamic and bold brushwork illustration, that captures earth tone colors and expressive metallic textures. Use dramatic lighting to create depth and contrast, enhancing the three-dimensional quality of the subject. Incorporate graphic elements and negative space effectively to frame the figure while maintaining a narrative quality within the artwork. The overall piece should exude a sense of refinement and modern sensibility, reflecting the craftsmanship and artistic innovation characteristic of Leyendecker\'s style. The composition should showcase a stylized figure in an elegant ((front)) pose, with a focus on capturing intricate details such as the texture of clothing, the play of light on skin, and the subtle expressions of emotion. ',
        isPro: true,
      ),
      ThemeCardModel(
        id: 'custom',
        title: 'Custom',
        imagePath: 'assets/themes/portrait.jpg',
        prompt: '',
        isPro: false,
      ),
      /* ThemeCardModel(
        id: 'food',
        title: '음식',
        imagePath: 'assets/themes/food.jpg',
        prompt: '완벽하게 플레이팅된 맛있어 보이는 음식',
        isPro: true,
      ),
      ThemeCardModel(
        id: 'animal',
        title: '동물',
        imagePath: 'assets/themes/animal.jpg',
        prompt: '자연 서식지에 있는 멋진 야생 동물',
        isPro: true,
      ),
      ThemeCardModel(
        id: 'ocean',
        title: '바다',
        imagePath: 'assets/themes/ocean.jpg',
        prompt: '푸른 바다와 흰 모래가 있는 평화로운 열대 해변',
        isPro: true,
      ),
      ThemeCardModel(
        id: 'art',
        title: '예술',
        imagePath: 'assets/themes/art.jpg',
        prompt: '화려한 색상과 질감이 있는 현대 미술 작품',
        isPro: true,
      ),
 */
    ];
  }
}
