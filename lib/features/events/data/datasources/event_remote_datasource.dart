import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Stream<List<EventModel>> watchHostEvents(String hostId);
  Stream<EventModel> watchEvent(String eventId);
  Future<String> createEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  @override
  Stream<List<EventModel>> watchHostEvents(String hostId) {
    return _events.where('hostId', isEqualTo: hostId).snapshots().map((
      snapshot,
    ) {
      final events = snapshot.docs.map(EventModel.fromFirestore).toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    });
  }

  @override
  Stream<EventModel> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) throw const ServerException('El evento ya no existe.');
      return EventModel.fromFirestore(doc);
    });
  }

  @override
  Future<String> createEvent(EventModel event) async {
    try {
      final ref = await _events.add({
        ...event.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo crear el evento.');
    }
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    try {
      // update() solo cambia estos campos; no borra la invitación
      // ni otros datos que se agreguen después.
      await _events.doc(event.id).update({
        ...event.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo actualizar el evento.');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _events.doc(eventId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo eliminar el evento.');
    }
  }
}
