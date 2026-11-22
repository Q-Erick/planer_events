import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/table_entity.dart';

class TableModel extends TableEntity {
  const TableModel({
    super.id,
    required super.eventId,
    required super.number,
    super.shape,
    super.x,
    super.y,
    super.seats,
    super.assignments,
  });

  factory TableModel.fromEntity(TableEntity t) {
    return TableModel(
      id: t.id,
      eventId: t.eventId,
      number: t.number,
      shape: t.shape,
      x: t.x,
      y: t.y,
      seats: t.seats,
      assignments: t.assignments,
    );
  }

  factory TableModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final raw = data['assignments'] as Map<String, dynamic>? ?? {};

    return TableModel(
      id: doc.id,
      eventId: doc.reference.parent.parent?.id ?? '',
      number: (data['number'] as num?)?.toInt() ?? 0,
      shape: TableShape.values.firstWhere(
        (s) => s.name == data['shape'],
        orElse: () => TableShape.round,
      ),
      x: (data['x'] as num?)?.toDouble() ?? 0.5,
      y: (data['y'] as num?)?.toDouble() ?? 0.5,
      seats: (data['seats'] as num?)?.toInt() ?? 10,
      assignments: {
        for (final entry in raw.entries)
          if (int.tryParse(entry.key) != null)
            int.parse(entry.key): entry.value as String,
      },
    );
  }

  static Map<String, String> assignmentsToFirestore(Map<int, String> map) =>
      map.map((seat, guestId) => MapEntry('$seat', guestId));

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'shape': shape.name,
      'x': x,
      'y': y,
      'seats': seats,
      'assignments': assignmentsToFirestore(assignments),
    };
  }
}
