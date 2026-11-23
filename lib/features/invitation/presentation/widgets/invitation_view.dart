import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_format.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/utils/event_type_ui.dart';
import '../../../events/presentation/widgets/event_location_map.dart';
import '../../domain/entities/invitation_config.dart';
import '../bloc/countdown_cubit.dart';

class InvitationView extends StatelessWidget {
  const InvitationView({
    super.key,
    required this.event,
    required this.config,
    this.footer,
  });

  final EventEntity event;
  final InvitationConfig config;

  /// Contenido extra al final (pase QR, cámara, etc.).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final accent = Color(config.colorValue);
    final onImage = config.hasBackground;
    final textColor = onImage ? Colors.white : const Color(0xFF2B2B2B);
    final titleStyle = GoogleFonts.getFont(config.fontFamily, color: textColor);
    final body = TextStyle(
      color: textColor.withValues(alpha: 0.9),
      fontSize: 15,
      height: 1.5,
    );

    Widget section(String title, IconData icon, Widget child) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onImage
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onImage ? Colors.white : accent),
                const SizedBox(width: 8),
                Text(title, style: titleStyle.copyWith(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: onImage
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.20),
                  Colors.white,
                  accent.withValues(alpha: 0.12),
                ],
              ),
        image: onImage
            ? DecorationImage(
                image: CachedNetworkImageProvider(config.backgroundUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.55),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      child: Column(
        children: [
          Text(
            event.type.label.toUpperCase(),
            style: TextStyle(
              color: onImage ? Colors.white70 : accent,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.name,
            textAlign: TextAlign.center,
            style: titleStyle.copyWith(fontSize: 40, height: 1.15),
          ),
          const SizedBox(height: 12),
          Text(
            '${AppDateFormat.long(event.date)}\n${AppDateFormat.time(event.date)}',
            textAlign: TextAlign.center,
            style: body,
          ),
          if (config.showMessage && config.message.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              config.message,
              textAlign: TextAlign.center,
              style: body.copyWith(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
          if (config.showCountdown) ...[
            const SizedBox(height: 24),
            _Countdown(
              key: ValueKey(event.date),
              date: event.date,
              accent: accent,
              onImage: onImage,
              textColor: textColor,
            ),
          ],
          if (config.showLocation && event.hasLocation)
            section(
              'Ubicación',
              Icons.place_outlined,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (event.venueName.isNotEmpty)
                    Text(
                      event.venueName,
                      textAlign: TextAlign.center,
                      style: body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  if (event.address.isNotEmpty)
                    Text(
                      event.address,
                      textAlign: TextAlign.center,
                      style: body,
                    ),
                  const SizedBox(height: 12),
                  EventLocationMap(
                    latitude: event.latitude!,
                    longitude: event.longitude!,
                    title: event.venueName.isEmpty
                        ? event.name
                        : event.venueName,
                  ),
                ],
              ),
            ),
          if (config.showItinerary && config.itinerary.isNotEmpty)
            section(
              'Itinerario',
              Icons.schedule,
              Column(
                children: [
                  for (final item in config.itinerary)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(
                              item.time,
                              style: body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onImage ? Colors.white : accent,
                              ),
                            ),
                          ),
                          Expanded(child: Text(item.title, style: body)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (config.showDressCode && config.dressCode.trim().isNotEmpty)
            section(
              'Código de vestimenta',
              Icons.checkroom_outlined,
              Text(
                config.dressCode,
                textAlign: TextAlign.center,
                style: body.copyWith(fontSize: 17),
              ),
            ),
          if (footer != null) ...[const SizedBox(height: 24), footer!],
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({
    super.key,
    required this.date,
    required this.accent,
    required this.onImage,
    required this.textColor,
  });

  final DateTime date;
  final Color accent;
  final bool onImage;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CountdownCubit(date),
      child: BlocBuilder<CountdownCubit, Duration>(
        builder: (context, left) {
          if (left == Duration.zero) {
            return Text(
              '¡Llegó el gran día!',
              style: TextStyle(
                color: onImage ? Colors.white : accent,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            );
          }

          final parts = [
            (left.inDays, 'días'),
            (left.inHours % 24, 'horas'),
            (left.inMinutes % 60, 'min'),
            (left.inSeconds % 60, 'seg'),
          ];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final part in parts)
                Container(
                  width: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: onImage
                        ? Colors.white.withValues(alpha: 0.15)
                        : accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${part.$1}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: onImage ? Colors.white : accent,
                        ),
                      ),
                      Text(
                        part.$2,
                        style: TextStyle(fontSize: 11, color: textColor),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
