import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/guest_model.dart';

abstract class GuestRemoteDataSource {
  Stream<List<GuestModel>> watchGuests(String eventId);
  Future<String> addGuest(GuestModel guest);
  Future<void> updateGuest(GuestModel guest);
  Future<void> deleteGuest(String eventId, String guestId);
}

class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  GuestRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _guests(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('guests');

  @override
  Stream<List<GuestModel>> watchGuests(String eventId) {
    return _guests(eventId).snapshots().map((snapshot) {
      final guests = snapshot.docs.map(GuestModel.fromFirestore).toList();
      guests.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return guests;
    });
  }

  @override
  Future<String> addGuest(GuestModel guest) async {
    try {
      final ref = await _guests(guest.eventId).add({
        ...guest.toFirestore(),
        'checkedIn': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo agregar el invitado.');
    }
  }

  @override
  Future<void> updateGuest(GuestModel guest) async {
    try {
      await _guests(guest.eventId).doc(guest.id).update(guest.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo actualizar el invitado.');
    }
  }

  @override
  Future<void> deleteGuest(String eventId, String guestId) async {
    try {
      await _guests(eventId).doc(guestId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo eliminar el invitado.');
    }
  }
}
