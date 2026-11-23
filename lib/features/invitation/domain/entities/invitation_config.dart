import 'package:equatable/equatable.dart';

import '../../../events/domain/entities/event_entity.dart';

class ItineraryItem extends Equatable {
  const ItineraryItem({required this.id, this.time = '', this.title = ''});

  final String id;

  /// Hora en formato 24 h "HH:mm".
  final String time;
  final String title;

  ItineraryItem copyWith({String? time, String? title}) => ItineraryItem(
    id: id,
    time: time ?? this.time,
    title: title ?? this.title,
  );

  @override
  List<Object> get props => [id, time, title];
}

/// Tipografías disponibles (nombres de Google Fonts).
const kInvitationFonts = [
  'Playfair Display',
  'Great Vibes',
  'Dancing Script',
  'Lora',
  'Montserrat',
];

/// Colores principales disponibles.
const kInvitationColors = [
  0xFF6D4C9F, // Morado
  0xFFC9A227, // Dorado
  0xFFB76E79, // Oro rosa
  0xFF2E5E4E, // Esmeralda
  0xFF1F3A5F, // Azul marino
  0xFFB23A48, // Vino
];

class InvitationConfig extends Equatable {
  const InvitationConfig({
    this.message = '',
    this.dressCode = '',
    this.itinerary = const [],
    this.showMessage = true,
    this.showCountdown = true,
    this.showLocation = true,
    this.showItinerary = true,
    this.showDressCode = true,
    this.fontFamily = 'Playfair Display',
    this.colorValue = 0xFF6D4C9F,
    this.backgroundUrl,
  });

  final String message;
  final String dressCode;
  final List<ItineraryItem> itinerary;
  final bool showMessage;
  final bool showCountdown;
  final bool showLocation;
  final bool showItinerary;
  final bool showDressCode;
  final String fontFamily;
  final int colorValue;
  final String? backgroundUrl;

  bool get hasBackground => backgroundUrl != null && backgroundUrl!.isNotEmpty;

  /// Plantilla inicial según el tipo de evento.
  factory InvitationConfig.defaultsFor(EventType type) {
    return switch (type) {
      EventType.wedding => const InvitationConfig(
        message:
            '¡Nos casamos! Nos encantaría que nos acompañes '
            'en este día tan especial.',
        dressCode: 'Formal',
        fontFamily: 'Great Vibes',
        colorValue: 0xFFC9A227,
        itinerary: [
          ItineraryItem(id: '1', time: '18:00', title: 'Ceremonia'),
          ItineraryItem(id: '2', time: '19:30', title: 'Recepción'),
          ItineraryItem(id: '3', time: '21:00', title: 'Cena'),
          ItineraryItem(id: '4', time: '22:00', title: 'Baile'),
        ],
      ),
      EventType.xv => const InvitationConfig(
        message: '¡Acompáñame a celebrar mis XV años!',
        dressCode: 'Formal',
        fontFamily: 'Dancing Script',
        colorValue: 0xFFB76E79,
        itinerary: [
          ItineraryItem(id: '1', time: '18:00', title: 'Misa'),
          ItineraryItem(id: '2', time: '20:00', title: 'Recepción'),
          ItineraryItem(id: '3', time: '21:00', title: 'Vals'),
        ],
      ),
      EventType.graduation => const InvitationConfig(
        message: '¡Lo logramos! Celebra con nosotros esta graduación.',
        dressCode: 'Semiformal',
        fontFamily: 'Playfair Display',
        colorValue: 0xFF1F3A5F,
      ),
      EventType.birthday => const InvitationConfig(
        message: '¡Ven a celebrar mi cumpleaños!',
        dressCode: 'Casual',
        fontFamily: 'Montserrat',
        colorValue: 0xFF6D4C9F,
      ),
      EventType.other => const InvitationConfig(
        message: '¡Estás invitado!',
        dressCode: 'Casual',
      ),
    };
  }

  /// Quita actividades sin nombre y las ordena por hora.
  InvitationConfig normalized() {
    final items = itinerary.where((i) => i.title.trim().isNotEmpty).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return copyWith(itinerary: items);
  }

  InvitationConfig copyWith({
    String? message,
    String? dressCode,
    List<ItineraryItem>? itinerary,
    bool? showMessage,
    bool? showCountdown,
    bool? showLocation,
    bool? showItinerary,
    bool? showDressCode,
    String? fontFamily,
    int? colorValue,
    String? backgroundUrl,
    bool clearBackground = false,
  }) {
    return InvitationConfig(
      message: message ?? this.message,
      dressCode: dressCode ?? this.dressCode,
      itinerary: itinerary ?? this.itinerary,
      showMessage: showMessage ?? this.showMessage,
      showCountdown: showCountdown ?? this.showCountdown,
      showLocation: showLocation ?? this.showLocation,
      showItinerary: showItinerary ?? this.showItinerary,
      showDressCode: showDressCode ?? this.showDressCode,
      fontFamily: fontFamily ?? this.fontFamily,
      colorValue: colorValue ?? this.colorValue,
      backgroundUrl: clearBackground
          ? null
          : (backgroundUrl ?? this.backgroundUrl),
    );
  }

  @override
  List<Object?> get props => [
    message,
    dressCode,
    itinerary,
    showMessage,
    showCountdown,
    showLocation,
    showItinerary,
    showDressCode,
    fontFamily,
    colorValue,
    backgroundUrl,
  ];
}
