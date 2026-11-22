import 'package:intl/intl.dart';

class AppDateFormat {
  AppDateFormat._();

  /// sábado 20 de diciembre de 2026
  static String long(DateTime d) =>
      DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(d);

  /// 20 dic 2026
  static String short(DateTime d) => DateFormat('d MMM y', 'es').format(d);

  /// 6:00 p. m.
  static String time(DateTime d) => DateFormat('h:mm a', 'es').format(d);
}
