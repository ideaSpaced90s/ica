// Tutorial System Constants and Configurations

/// Current data version of the tutorial system.
/// Incremented whenever breaking changes are made to lesson structures or steps.
const int kTutorialDataVersion = 2;

/// Total number of tutorial chapters available in the academy flow.
const int kTutorialChapterCount = 55;

/// Represents the earned status/rank of the player in the Academy Tutorial.
enum TutorialRank {
  beginner('Beginner', 0),
  apprentice('Apprentice', 100),
  student('Student', 250),
  practitioner('Practitioner', 500),
  scholar('Scholar', 800),
  candidate('Candidate', 1200),
  expert('Expert', 1800),
  graduate('Academy Graduate', 2500);

  final String displayName;
  final int minXp;

  const TutorialRank(this.displayName, this.minXp);

  static TutorialRank fromXp(int xp) {
    TutorialRank current = TutorialRank.beginner;
    for (final rank in TutorialRank.values) {
      if (xp >= rank.minXp) {
        current = rank;
      } else {
        break;
      }
    }
    return current;
  }
}

/// Standard XP rewards for chapter completion based on star ratings.
class TutorialRewards {
  static const int baseChapterCompletionXp = 50;
  static const int perStarBonusXp = 25; // 3 stars = 50 + 75 = 125 XP

  static int calculateXp(int stars) {
    if (stars <= 0) return baseChapterCompletionXp;
    return baseChapterCompletionXp + (stars * perStarBonusXp);
  }
}
