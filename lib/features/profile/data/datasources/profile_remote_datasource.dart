import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';

abstract class ProfileRemoteDataSource {
  Future<String> uploadPhoto(Uint8List bytes);
  Future<void> updateDisplayName(String name);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseStorage storage,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _storage = storage,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('No hay sesión activa.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<String> uploadPhoto(Uint8List bytes) async {
    final user = _user;
    try {
      final ref = _storage.ref('users/${user.uid}/avatar.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final url = await ref.getDownloadURL();
      // Versión para que la caché detecte la foto nueva
      final versionedUrl = '$url&v=${DateTime.now().millisecondsSinceEpoch}';

      await _userDoc(user.uid).set({
        'photoUrl': versionedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Esto dispara userChanges() → la foto se actualiza en toda la app
      await user.updatePhotoURL(versionedUrl);
      return versionedUrl;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo subir la foto.');
    }
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _user;
    try {
      await _userDoc(user.uid).set({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updateDisplayName(name);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'No se pudo actualizar el nombre.');
    }
  }
}
