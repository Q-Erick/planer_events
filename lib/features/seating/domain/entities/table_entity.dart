import 'package:equatable/equatable.dart';

enum TableShape { round, square, rectangle }

class TableEntity extends Equatable {
  const TableEntity({
    this.id = '',
    required this.eventId,
    required this.number,
    this.shape = TableShape.round,
    this.x = 0.5,
    this.y = 0.5,
    this.seats = 10,
    this.assignments = const {},
  });

  final String id;
  final String eventId;

  /// Número visible de la mesa (1, 2, 3...).
  final int number;
  final TableShape shape;

  /// Posición relativa dentro del salón (0 a 1).
  /// Así el plano se ve igual en cualquier tamaño de pantalla.
  final double x;
  final double y;

  /// Número de sillas de esta mesa.
  final int seats;

  /// Silla → id del invitado sentado ahí.
  final Map<int, String> assignments;

  bool isSeatTaken(int seat) => assignments.containsKey(seat);

  int get occupiedCount => assignments.length;

  int get freeCount => seats - occupiedCount;

  /// Cuántas sillas de esta mesa ocupa un invitado.
  int seatsOf(String guestId) =>
      assignments.values.where((id) => id == guestId).length;

  TableEntity copyWith({
    String? id,
    String? eventId,
    int? number,
    TableShape? shape,
    double? x,
    double? y,
    int? seats,
    Map<int, String>? assignments,
  }) {
    return TableEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      number: number ?? this.number,
      shape: shape ?? this.shape,
      x: x ?? this.x,
      y: y ?? this.y,
      seats: seats ?? this.seats,
      assignments: assignments ?? this.assignments,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    number,
    shape,
    x,
    y,
    seats,
    assignments,
  ];
}
