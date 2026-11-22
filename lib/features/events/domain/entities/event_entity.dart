import 'package:equatable/equatable.dart';

enum EventType { wedding, xv, graduation, birthday, other }

class EventEntity extends Equatable {
  const EventEntity({
    this.id = '',
    required this.hostId,
    required this.name,
    required this.type,
    required this.date,
    this.venueName = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.maxGuests = 100,
  });

  final String id;
  final String hostId;
  final String name;
  final EventType type;
  final DateTime date;
  final String venueName;
  final String address;
  final double? latitude;
  final double? longitude;

  /// Número máximo de invitados que definió el anfitrión.
  final int maxGuests;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isPast => !isToday && date.isBefore(DateTime.now());

  EventEntity copyWith({
    String? id,
    String? hostId,
    String? name,
    EventType? type,
    DateTime? date,
    String? venueName,
    String? address,
    double? latitude,
    double? longitude,
    int? maxGuests,
  }) {
    return EventEntity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxGuests: maxGuests ?? this.maxGuests,
    );
  }

  @override
  List<Object?> get props => [
    id,
    hostId,
    name,
    type,
    date,
    venueName,
    address,
    latitude,
    longitude,
    maxGuests,
  ];
}
