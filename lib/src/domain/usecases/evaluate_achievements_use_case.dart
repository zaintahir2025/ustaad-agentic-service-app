import '../entities/achievement_badge.dart';

/// Result produced when checking and evaluating user achievements.
class AchievementEvaluationResult {
  const AchievementEvaluationResult({
    required this.allBadges,
    required this.newlyUnlocked,
  });

  final List<AchievementBadge> allBadges;
  final List<AchievementBadge> newlyUnlocked;
}

/// Clean Architecture Use Case: Evaluates milestones and unlocks achievement badges.
class EvaluateAchievementsUseCase {
  const EvaluateAchievementsUseCase();

  /// Evaluates current state conditions and unlocks qualifying badges.
  AchievementEvaluationResult execute({
    required String lastProblem,
    required int totalBookingsCount,
    String? language,
    required List<AchievementBadge> currentBadges,
  }) {
    var badges = List<AchievementBadge>.from(currentBadges);
    final newlyUnlocked = <AchievementBadge>[];

    void unlock(String id) {
      final index = badges.indexWhere((badge) => badge.id == id);
      if (index == -1 || badges[index].unlocked) return;
      final unlocked = badges[index].copyWith(
        unlocked: true,
        unlockedAt: DateTime.now(),
      );
      badges[index] = unlocked;
      newlyUnlocked.add(unlocked);
    }

    if (lastProblem.isNotEmpty) {
      unlock('first_request');
    }
    if (totalBookingsCount >= 1) {
      unlock('first_booking');
    }
    if (totalBookingsCount >= 3) {
      unlock('power_user');
    }
    if (language == 'Roman Urdu' || language == 'Urdu') {
      unlock('multilingual');
    }

    return AchievementEvaluationResult(
      allBadges: badges,
      newlyUnlocked: newlyUnlocked,
    );
  }

  /// Manually unlocks an emergency or special achievement badge by [id].
  AchievementEvaluationResult unlockById({
    required String id,
    required List<AchievementBadge> currentBadges,
  }) {
    var badges = List<AchievementBadge>.from(currentBadges);
    final newlyUnlocked = <AchievementBadge>[];

    final index = badges.indexWhere((badge) => badge.id == id);
    if (index != -1 && !badges[index].unlocked) {
      final unlocked = badges[index].copyWith(
        unlocked: true,
        unlockedAt: DateTime.now(),
      );
      badges[index] = unlocked;
      newlyUnlocked.add(unlocked);
    }

    return AchievementEvaluationResult(
      allBadges: badges,
      newlyUnlocked: newlyUnlocked,
    );
  }
}
