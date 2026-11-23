import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../domain/entities/invitation_config.dart';
import '../models/invitation_config_model.dart';

abstract class InvitationRemoteDataSource {
  Stream<InvitationConfig> watchInvitation(String eventId);
  Future<void> saveInvitation(String eventId, InvitationConfig config);
  Future<String> uploadBackground(String eventId, Uint8List bytes);
}

class InvitationRemoteDataSourceImpl implements InvitationRemoteDataSource {
  InvitationRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _event(String id) =>
      _firestore.collection('events').doc(id);

  @override
  Stream<InvitationConfig> watchInvitation(String eventId) {
    return _event(eventId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) throw const ServerException('El evento ya no existe.');
      final type = EventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => EventType.other,
      );
      final raw = data['invitation'];
      return InvitationConfigModel.fromMap(
        raw is Map ? Map<String, dynamic>.from(raw) : null,
        type,
      );
    });
  }

  @override
  Future<void> saveInvitation(String eventId, InvitationConfig config) async {
    try {
      await _event(eventId).update({
        'invitation': InvitationConfigModel.toMap(config),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo guardar la invitación.');
    }
  }

  @override
  Future<String> uploadBackground(String eventId, Uint8List bytes) async {
    try {
      final ref = _storage.ref('events/$eventId/invitation/background.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      // Versión para que la caché detecte la imagen nueva
      return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo subir la imagen.');
    }
  }
}
