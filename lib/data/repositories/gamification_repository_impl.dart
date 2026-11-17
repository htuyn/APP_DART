import '../../domain/repositories/i_gamification_repository.dart';
import '../datasources/gamification_storage_datasource.dart';
import '../models/gamification_model.dart';

class GamificationRepositoryImpl implements IGamificationRepository {
  const GamificationRepositoryImpl(this.dataSource);

  final GamificationStorageDataSource dataSource;

  @override
  Future<GamificationModel> load() => dataSource.load();

  @override
  Future<void> save(GamificationModel progress) => dataSource.save(progress);
}
