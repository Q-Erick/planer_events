import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/guest_entity.dart';

class GuestModel extends GuestEntity {
  const GuestModel({
    super.id,
    required super.eventId,
    required super.name,
    super.phone,
    super.passes,
    super.checkedIn,
    super.checkedInAt,
  });

  factory GuestModel.fromEntity(GuestEntity g) {
    return GuestModel(
      id: g.id,
      eventId: g.eventId,
      name: g.name,
      phone: g.phone,
      passes: g.passes,
      checkedIn: g.checkedIn,
      checkedInAt: g.checkedInAt,
    );
  }

  factory GuestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GuestModel(
      id: doc.id,
      // events/{eventId}/guests/{guestId}
      eventId: doc.reference.parent.parent?.id ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      passes: (data['passes'] as num?)?.toInt() ?? 1,
      checkedIn: data['checkedIn'] as bool? ?? false,
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name.trim(), 'phone': phone.trim(), 'passes': passes};
  }
}
