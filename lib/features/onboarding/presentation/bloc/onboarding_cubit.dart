import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit(this._completeOnboarding) : super(0);

  final CompleteOnboarding _completeOnboarding;
  final PageController pageController = PageController();

  void onPageChanged(int index) => emit(index);

  void next() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> finish() async {
    await _completeOnboarding(const NoParams());
  }

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
