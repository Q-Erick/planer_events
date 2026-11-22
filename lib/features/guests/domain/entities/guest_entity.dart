import 'package:equatable/equatable.dart';

/// Un invitado es un "pase": puede ser una persona o un grupo
/// (ej. "Familia Pérez" con 4 lugares).
class GuestEntity extends Equatable {
  const GuestEntity({
    this.id = '',
    required this.eventId,
    required this.name,
    this.phone = '',
    this.passes = 1,
    this.checkedIn = false,
    this.checkedInAt,
  });

  final String id;
  final String eventId;

  /// Titular del pase: "Juan López" o "Familia Pérez".
  final String name;
  final String phone;

  /// Número de lugares que incluye el pase.
  final int passes;

  final bool checkedIn;
  final DateTime? checkedInAt;

  /// Contenido del código QR del pase.
  String get qrData => 'planer:$eventId:$id';

  GuestEntity copyWith({
    String? id,
    String? eventId,
    String? name,
    String? phone,
    int? passes,
    bool? checkedIn,
    DateTime? checkedInAt,
  }) {
    return GuestEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      passes: passes ?? this.passes,
      checkedIn: checkedIn ?? this.checkedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    name,
    phone,
    passes,
    checkedIn,
    checkedInAt,
  ];
}
