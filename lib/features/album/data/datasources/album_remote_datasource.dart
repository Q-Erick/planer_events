import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/photo_entity.dart';
import '../models/photo_model.dart';

abstract class AlbumRemoteDataSource {
  Stream<List<PhotoModel>> watchPhotos(String eventId);
  Future<void> uploadPhoto({
    required String eventId,
    required Uint8List bytes,
    required String uploaderId,
    required String uploaderName,
  });
  Future<void> deletePhoto(PhotoEntity photo);
}

class AlbumRemoteDataSourceImpl implements AlbumRemoteDataSource {
  AlbumRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _photos(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('photos');

  @override
  Stream<List<PhotoModel>> watchPhotos(String eventId) {
    return _photos(eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PhotoModel.fromFirestore).toList());
  }

  @override
  Future<void> uploadPhoto({
    required String eventId,
    required Uint8List bytes,
    required String uploaderId,
    required String uploaderName,
  }) async {
    try {
      final doc = _photos(eventId).doc(); // genera el id
      final path = 'events/$eventId/photos/${doc.id}.jpg';
      final ref = _storage.ref(path);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await doc.set({
        'url': url,
        'storagePath': path,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo subir la foto.');
    }
  }

  @override
  Future<void> deletePhoto(PhotoEntity photo) async {
    try {
      // Si el archivo ya no existe, igual borramos el registro
      try {
        await _storage.ref(photo.storagePath).delete();
      } catch (_) {}
      await _photos(photo.eventId).doc(photo.id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo eliminar la foto.');
    }
  }
}
