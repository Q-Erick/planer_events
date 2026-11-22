import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/table_model.dart';

/// Sillas por mesa si el anfitrión no ha configurado otra cantidad.
const kDefaultSeatsPerTable = 10;

abstract class SeatingRemoteDataSource {
  Stream<List<TableModel>> watchTables(String eventId);
  Stream<int> watchSeatsPerTable(String eventId);
  Future<void> setSeatsPerTable(String eventId, int seats);
  Future<void> addTable(TableModel table);
  Future<void> updateTable(TableModel table);
  Future<void> moveTable(String eventId, String tableId, double x, double y);
  Future<void> deleteTable(String eventId, String tableId);
  Future<void> saveAssignments(
    String eventId,
    Map<String, Map<int, String>> assignmentsByTable,
  );
  Future<void> releaseGuestEverywhere(String eventId, String guestId);
}

class SeatingRemoteDataSourceImpl implements SeatingRemoteDataSource {
  SeatingRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _event(String eventId) =>
      _firestore.collection('events').doc(eventId);

  CollectionReference<Map<String, dynamic>> _tables(String eventId) =>
      _event(eventId).collection('tables');

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? message);
    }
  }

  @override
  Stream<List<TableModel>> watchTables(String eventId) {
    return _tables(eventId).snapshots().map((snapshot) {
      final tables = snapshot.docs.map(TableModel.fromFirestore).toList();
      tables.sort((a, b) => a.number.compareTo(b.number));
      return tables;
    });
  }

  @override
  Stream<int> watchSeatsPerTable(String eventId) {
    return _event(eventId).snapshots().map(
      (doc) =>
          (doc.data()?['seatsPerTable'] as num?)?.toInt() ??
          kDefaultSeatsPerTable,
    );
  }

  @override
  Future<void> setSeatsPerTable(String eventId, int seats) => _run(
    () => _event(eventId).update({'seatsPerTable': seats}),
    'No se pudo guardar el número de sillas.',
  );

  @override
  Future<void> addTable(TableModel table) => _run(
    () => _tables(
      table.eventId,
    ).add({...table.toFirestore(), 'createdAt': FieldValue.serverTimestamp()}),
    'No se pudo agregar la mesa.',
  );

  @override
  Future<void> updateTable(TableModel table) => _run(
    () =>
        _tables(table.eventId)
            .doc(table.id)
            .update({'shape': table.shape.name, 'seats': table.seats}),
    'No se pudo actualizar la mesa.',
  );

  @override
  Future<void> moveTable(String eventId, String tableId, double x, double y) =>
      _run(
        () => _tables(eventId).doc(tableId).update({'x': x, 'y': y}),
        'No se pudo mover la mesa.',
      );

  @override
  Future<void> deleteTable(String eventId, String tableId) => _run(
    () => _tables(eventId).doc(tableId).delete(),
    'No se pudo eliminar la mesa.',
  );

  @override
  Future<void> saveAssignments(
    String eventId,
    Map<String, Map<int, String>> assignmentsByTable,
  ) => _run(() async {
    final batch = _firestore.batch();
    assignmentsByTable.forEach((tableId, assignments) {
      batch.update(_tables(eventId).doc(tableId), {
        'assignments': TableModel.assignmentsToFirestore(assignments),
      });
    });
    await batch.commit();
  }, 'No se pudo guardar la asignación.');

  @override
  Future<void> releaseGuestEverywhere(String eventId, String guestId) =>
      _run(() async {
        final snapshot = await _tables(eventId).get();
        final batch = _firestore.batch();
        var changed = false;

        for (final doc in snapshot.docs) {
          final table = TableModel.fromFirestore(doc);
          if (table.seatsOf(guestId) == 0) continue;
          final updated = Map<int, String>.from(table.assignments)
            ..removeWhere((_, id) => id == guestId);
          batch.update(doc.reference, {
            'assignments': TableModel.assignmentsToFirestore(updated),
          });
          changed = true;
        }
        if (changed) await batch.commit();
      }, 'No se pudieron liberar las sillas.');
}
