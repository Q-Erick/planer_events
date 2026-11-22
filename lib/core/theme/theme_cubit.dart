import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _load(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_key, mode.name);
  }

  /// Cambia entre claro y oscuro según el brillo actual.
  Future<void> toggle(Brightness current) {
    return setTheme(
      current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
