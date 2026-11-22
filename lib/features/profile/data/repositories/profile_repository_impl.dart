import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> updatePhoto(Uint8List bytes) =>
      _guard(() => _remote.uploadPhoto(bytes));

  @override
  Future<Either<Failure, Unit>> updateDisplayName(String name) =>
      _guard(() async {
        await _remote.updateDisplayName(name);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }
}
