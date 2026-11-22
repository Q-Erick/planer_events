import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingLocalDataSource {
  bool isCompleted();
  Future<void> markCompleted();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'onboarding_completed';

  @override
  bool isCompleted() => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markCompleted() async {
    await _prefs.setBool(_key, true);
  }
}
