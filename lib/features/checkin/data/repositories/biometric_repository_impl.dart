import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../datasources/biometric_datasource.dart';

class BiometricRepositoryImpl implements BiometricRepository {
  BiometricRepositoryImpl(this._dataSource);

  final BiometricDataSource _dataSource;

  @override
  Future<Either<Failure, bool>> authenticate(String reason) async {
    try {
      return right(await _dataSource.authenticate(reason));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (_) {
      return left(const AuthFailure('No se pudo usar el sensor biométrico.'));
    }
  }
}
