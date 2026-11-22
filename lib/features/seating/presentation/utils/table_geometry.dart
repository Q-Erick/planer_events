import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/entities/table_entity.dart';

/// Tamaño lógico del salón. Las mesas guardan su posición
/// relativa (0 a 1) y se dibujan dentro de este espacio.
const kVenueSize = Size(900, 600);

class TableGeometry {
  const TableGeometry._({
    required this.boxSize,
    required this.tableSize,
    required this.chairSize,
    required this.chairCenters,
  });

  /// Espacio total que ocupa la mesa con sus sillas.
  final Size boxSize;
  final Size tableSize;
  final double chairSize;

  /// Centro de cada silla, relativo al centro de la mesa,
  /// en orden horario.
  final List<Offset> chairCenters;

  static const double _gap = 5;

  factory TableGeometry.of(TableShape shape, int seats) {
    // Más sillas → sillas más pequeñas
    final chair = (24 - seats * 0.6).clamp(11.0, 20.0);
    return switch (shape) {
      TableShape.round => _round(seats, chair),
      TableShape.square => _square(seats, chair),
      TableShape.rectangle => _rectangle(seats, chair),
    };
  }

  static TableGeometry _round(int seats, double chair) {
    // Radio necesario para que quepan todas las sillas alrededor
    final ringRadius = math.max(seats * (chair + 4) / (2 * math.pi), 40.0);
    final tableRadius = ringRadius - chair / 2 - _gap;

    final centers = List.generate(seats, (i) {
      final angle = -math.pi / 2 + 2 * math.pi * i / seats;
      return Offset(math.cos(angle) * ringRadius, math.sin(angle) * ringRadius);
    });
    return _build(Size.square(tableRadius * 2), chair, centers);
  }

  static TableGeometry _square(int seats, double chair) {
    // Reparte las sillas lo más parejo posible en los 4 lados
    final base = seats ~/ 4;
    final extra = seats % 4;
    final perSide = List.generate(4, (i) => base + (i < extra ? 1 : 0));
    final maxPerSide = perSide.reduce(math.max);
    final side = math.max(56.0, maxPerSide * (chair + 4) + 12);
    final size = Size.square(side);
    return _build(size, chair, _alongSides(size, perSide, chair));
  }

  static TableGeometry _rectangle(int seats, double chair) {
    // Una silla en cada cabecera (si hay 6 o más) y el resto en los lados largos
    final ends = seats >= 6 ? 1 : 0;
    final longSides = seats - ends * 2;
    final top = (longSides + 1) ~/ 2;
    final bottom = longSides - top;
    final perSide = [top, ends, bottom, ends];

    final width = math.max(100.0, top * (chair + 4) + 16);
    final height = math.max(48.0, ends * (chair + 4) + 20);
    final size = Size(width, height);
    return _build(size, chair, _alongSides(size, perSide, chair));
  }

  /// Coloca las sillas en sentido horario:
  /// arriba (izq→der), derecha (arriba→abajo),
  /// abajo (der→izq) e izquierda (abajo→arriba).
  static List<Offset> _alongSides(Size table, List<int> perSide, double chair) {
    final hw = table.width / 2;
    final hh = table.height / 2;
    final d = chair / 2 + _gap;
    final out = <Offset>[];

    double t(int k, int n, double length) =>
        -length / 2 + length * (k + 0.5) / n;

    for (var k = 0; k < perSide[0]; k++) {
      out.add(Offset(t(k, perSide[0], table.width), -hh - d));
    }
    for (var k = 0; k < perSide[1]; k++) {
      out.add(Offset(hw + d, t(k, perSide[1], table.height)));
    }
    for (var k = 0; k < perSide[2]; k++) {
      out.add(Offset(-t(k, perSide[2], table.width), hh + d));
    }
    for (var k = 0; k < perSide[3]; k++) {
      out.add(Offset(-hw - d, -t(k, perSide[3], table.height)));
    }
    return out;
  }

  static TableGeometry _build(Size table, double chair, List<Offset> centers) {
    var halfW = table.width / 2;
    var halfH = table.height / 2;
    for (final c in centers) {
      halfW = math.max(halfW, c.dx.abs() + chair / 2);
      halfH = math.max(halfH, c.dy.abs() + chair / 2);
    }
    return TableGeometry._(
      boxSize: Size(halfW * 2 + 4, halfH * 2 + 4),
      tableSize: table,
      chairSize: chair,
      chairCenters: centers,
    );
  }
}
