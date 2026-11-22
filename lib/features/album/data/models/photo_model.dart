import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.id,
    required super.eventId,
    required super.url,
    required super.storagePath,
    required super.uploaderId,
    required super.uploaderName,
    required super.createdAt,
  });

  factory PhotoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PhotoModel(
      id: doc.id,
      eventId: doc.reference.parent.parent?.id ?? '',
      url: data['url'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      uploaderId: data['uploaderId'] as String? ?? '',
      uploaderName: data['uploaderName'] as String? ?? '',
      // Justo después de subirla, la fecha del servidor aún no llega
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
