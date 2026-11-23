import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class CountdownCubit extends Cubit<Duration> {
  CountdownCubit(this.target) : super(_left(target)) {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(_left(target)),
    );
  }

  final DateTime target;
  late final Timer _timer;

  static Duration _left(DateTime target) {
    final diff = target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
