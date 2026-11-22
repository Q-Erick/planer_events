import 'package:material_ui/material_ui.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? scheme.onError : null),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? scheme.error : null,
      ),
    );
}
