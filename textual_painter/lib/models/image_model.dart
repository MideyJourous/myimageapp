class GeneratedImage {
  final String id;
  final String prompt;
  final String imageUrl;
  final String? model; // SDXL 또는 Flux Schnell
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    this.model,
    required this.createdAt,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'model': model,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'],
      prompt: json['prompt'],
      imageUrl: json['imageUrl'],
      model: json['model'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}