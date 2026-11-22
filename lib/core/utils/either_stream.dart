import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../errors/exceptions.dart';
import '../errors/failures.dart';

extension EitherStream<T> on Stream<T> {
  Stream<Either<Failure, T>> toEither() {
    return transform(
      StreamTransformer<T, Either<Failure, T>>.fromHandlers(
        handleData: (data, sink) => sink.add(right(data)),
        handleError: (error, stackTrace, sink) => sink.add(
          left(
            ServerFailure(
              error is ServerException
                  ? error.message
                  : 'No se pudieron cargar los datos.',
            ),
          ),
        ),
      ),
    );
  }
}
