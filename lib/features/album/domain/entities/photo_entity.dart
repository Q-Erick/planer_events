import 'package:equatable/equatable.dart';

class PhotoEntity extends Equatable {
  const PhotoEntity({
    required this.id,
    required this.eventId,
    required this.url,
    required this.storagePath,
    required this.uploaderId,
    required this.uploaderName,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String url;
  final String storagePath;
  final String uploaderId;
  final String uploaderName;
  final DateTime createdAt;

  @override
  List<Object> get props => [
    id,
    eventId,
    url,
    storagePath,
    uploaderId,
    uploaderName,
    createdAt,
  ];
}
