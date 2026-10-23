/// Domain Entity representing a gamification badge and unlock status.
class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  AchievementBadge copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementBadge(
      id: id,
      title: title,
      emoji: emoji,
      description: description,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static List<AchievementBadge> defaultBadges() {
    return const [
      AchievementBadge(
        id: 'first_request',
        title: 'First Request',
        emoji: '🚀',
        description: 'Made your first service request',
      ),
      AchievementBadge(
        id: 'first_booking',
        title: 'First Booking',
        emoji: '🏆',
        description: 'Successfully booked your first Ustaad',
      ),
      AchievementBadge(
        id: 'multilingual',
        title: 'Language Master',
        emoji: '🌐',
        description: 'Used Urdu or Roman Urdu input',
      ),
      AchievementBadge(
        id: 'emergency_hero',
        title: 'Emergency Hero',
        emoji: '⚡',
        description: 'Used Emergency Fast-Track mode',
      ),
      AchievementBadge(
        id: 'power_user',
        title: 'Power User',
        emoji: '💎',
        description: 'Made 3 or more bookings',
      ),
    ];
  }
}
