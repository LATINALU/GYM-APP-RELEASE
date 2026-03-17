/// Social / Community domain entity
/// User posts, challenges, and community interactions
class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final SocialPostType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isLiked;

  SocialPost({required this.id, required this.userId, required this.userName,
    this.userPhotoUrl, required this.type, required this.content,
    this.metadata, required this.createdAt, this.likes = 0,
    this.comments = 0, this.isLiked = false});

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'userName': userName,
    'userPhotoUrl': userPhotoUrl, 'type': type.name,
    'content': content, 'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes, 'comments': comments};

  factory SocialPost.fromMap(Map<String, dynamic> m) => SocialPost(
    id: m['id'] ?? '', userId: m['userId'] ?? '', userName: m['userName'] ?? '',
    userPhotoUrl: m['userPhotoUrl'], content: m['content'] ?? '',
    type: SocialPostType.values.firstWhere((e) => e.name == m['type'], orElse: () => SocialPostType.general),
    metadata: m['metadata'], createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    likes: m['likes'] ?? 0, comments: m['comments'] ?? 0);
}

enum SocialPostType {
  workout, achievement, pr, streak, challenge, general;

  String get displayName {
    switch (this) {
      case workout: return 'Entrenamiento';
      case achievement: return 'Logro';
      case pr: return 'Récord Personal';
      case streak: return 'Racha';
      case challenge: return 'Desafío';
      case general: return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case workout: return '💪';
      case achievement: return '🏆';
      case pr: return '🏋️';
      case streak: return '🔥';
      case challenge: return '⚔️';
      case general: return '📝';
    }
  }
}

/// Weekly challenge for community engagement
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final int participants;
  final int xpReward;

  WeeklyChallenge({required this.id, required this.title, required this.description,
    required this.type, required this.targetValue, required this.unit,
    required this.startDate, required this.endDate,
    required this.participants, required this.xpReward});
}

enum ChallengeType {
  workoutCount, totalVolume, caloriesBurned, streakDays, specificExercise;
}
