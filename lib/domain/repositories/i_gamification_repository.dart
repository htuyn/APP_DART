import '../../data/models/gamification_model.dart';

/// Persistence contract for gamification progress.
abstract interface class IGamificationRepository {
  Future<GamificationModel> load();
  Future<void> save(GamificationModel progress);
}
