import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    super.id,
    required super.hostId,
    required super.name,
    required super.type,
    required super.date,
    super.venueName,
    super.address,
    super.latitude,
    super.longitude,
    super.maxGuests,
  });

  factory EventModel.fromEntity(EventEntity e) {
    return EventModel(
      id: e.id,
      hostId: e.hostId,
      name: e.name,
      type: e.type,
      date: e.date,
      venueName: e.venueName,
      address: e.address,
      latitude: e.latitude,
      longitude: e.longitude,
      maxGuests: e.maxGuests,
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final location = data['location'] as GeoPoint?;

    return EventModel(
      id: doc.id,
      hostId: data['hostId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: EventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => EventType.other,
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      venueName: data['venueName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
      maxGuests: (data['maxGuests'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'name': name.trim(),
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'venueName': venueName.trim(),
      'address': address.trim(),
      'location': hasLocation ? GeoPoint(latitude!, longitude!) : null,
      'maxGuests': maxGuests,
    };
  }
}
