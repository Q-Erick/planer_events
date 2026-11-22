class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? required(String value, String field) =>
      value.trim().isEmpty ? 'Ingresa $field.' : null;

  static String? email(String value) {
    if (value.trim().isEmpty) return 'Ingresa tu correo.';
    if (!_emailRegex.hasMatch(value.trim())) return 'El correo no es válido.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Ingresa una contraseña.';
    if (value.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value.isEmpty) return 'Confirma tu contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }
}
