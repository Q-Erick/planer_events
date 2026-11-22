import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

class IsOnboardingCompleted {
  const IsOnboardingCompleted(this._repository);
  final OnboardingRepository _repository;

  bool call() => _repository.isCompleted();
}

class CompleteOnboarding implements UseCase<Unit, NoParams> {
  const CompleteOnboarding(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.complete();
}
