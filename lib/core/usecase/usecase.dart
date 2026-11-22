import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

/// Caso de uso que devuelve un resultado una sola vez.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Caso de uso que escucha cambios en tiempo real (Firestore).
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// Para casos de uso que no reciben parámetros.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
