class GeneratedImage {
  final String id;
  final String prompt;
  final String imageUrl;
  final String? model; // SDXL 또는 Flux Schnell
  final DateTime createdAt;
  final String userId;

  GeneratedImage({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    this.model,
    required this.createdAt,
    required this.userId,
  });

  // Firestore에서 사용할 toMap 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'model': model,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  // Firestore 데이터로부터 객체 생성
  factory GeneratedImage.fromMap(Map<String, dynamic> map) {
    return GeneratedImage(
      id: map['id'] as String,
      prompt: map['prompt'] as String,
      imageUrl: map['imageUrl'] as String,
      model: map['model'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as String,
    );
  }

  // 객체 복사본 생성
  GeneratedImage copyWith({
    String? id,
    String? prompt,
    String? imageUrl,
    String? model,
    DateTime? createdAt,
    String? userId,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
