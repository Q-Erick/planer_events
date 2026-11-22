import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  bool isCompleted() => _local.isCompleted();

  @override
  Future<Either<Failure, Unit>> complete() async {
    try {
      await _local.markCompleted();
      return right(unit);
    } catch (_) {
      return left(const CacheFailure());
    }
  }
}
