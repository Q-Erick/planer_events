import 'package:material_ui/material_ui.dart';

import '../../domain/entities/table_entity.dart';

extension TableShapeUi on TableShape {
  String get label => switch (this) {
    TableShape.round => 'Redonda',
    TableShape.square => 'Cuadrada',
    TableShape.rectangle => 'Rectangular',
  };

  IconData get icon => switch (this) {
    TableShape.round => Icons.circle_outlined,
    TableShape.square => Icons.crop_square,
    TableShape.rectangle => Icons.crop_16_9,
  };
}
