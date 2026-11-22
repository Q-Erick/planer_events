import 'package:material_ui/material_ui.dart';

import '../../domain/entities/table_entity.dart';
import '../utils/table_geometry.dart';

class TableView extends StatelessWidget {
  const TableView({
    super.key,
    required this.table,
    this.highlightGuestId,
    this.isDragging = false,
    this.onTableTap,
    this.onSeatTap,
  });

  final TableEntity table;

  /// Resalta las sillas de este invitado (grupo pendiente).
  final String? highlightGuestId;
  final bool isDragging;
  final VoidCallback? onTableTap;
  final void Function(int seat)? onSeatTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final geometry = TableGeometry.of(table.shape, table.seats);
    final box = geometry.boxSize;
    final chair = geometry.chairSize;
    final isRound = table.shape == TableShape.round;

    return SizedBox.fromSize(
      size: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ---------- Mesa ----------
          Center(
            child: GestureDetector(
              onTap: onTableTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: geometry.tableSize.width,
                height: geometry.tableSize.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: isRound ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isRound ? null : BorderRadius.circular(8),
                  border: Border.all(
                    color: isDragging ? scheme.primary : scheme.outline,
                    width: isDragging ? 2.5 : 1.5,
                  ),
                  boxShadow: isDragging
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${table.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          // ---------- Sillas ----------
          for (var i = 0; i < geometry.chairCenters.length; i++)
            Positioned(
              left: geometry.chairCenters[i].dx + box.width / 2 - chair / 2,
              top: geometry.chairCenters[i].dy + box.height / 2 - chair / 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSeatTap == null ? null : () => onSeatTap!(i),
                child: _Chair(
                  size: chair,
                  isTaken: table.isSeatTaken(i),
                  isHighlighted:
                      highlightGuestId != null &&
                      table.assignments[i] == highlightGuestId,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chair extends StatelessWidget {
  const _Chair({
    required this.size,
    required this.isTaken,
    required this.isHighlighted,
  });

  final double size;
  final bool isTaken;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = isHighlighted
        ? scheme.secondary
        : isTaken
        ? scheme.primary
        : scheme.surface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isTaken || isHighlighted ? fill : scheme.outline,
          width: 1.2,
        ),
      ),
    );
  }
}
