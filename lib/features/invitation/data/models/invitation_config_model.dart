import '../../../events/domain/entities/event_entity.dart';
import '../../domain/entities/invitation_config.dart';

class InvitationConfigModel {
  InvitationConfigModel._();

  /// Si el evento aún no tiene invitación, usa la plantilla de su tipo.
  static InvitationConfig fromMap(Map<String, dynamic>? map, EventType type) {
    final defaults = InvitationConfig.defaultsFor(type);
    if (map == null) return defaults;

    final rawItems = map['itinerary'] as List<dynamic>? ?? const [];
    return InvitationConfig(
      message: map['message'] as String? ?? defaults.message,
      dressCode: map['dressCode'] as String? ?? defaults.dressCode,
      itinerary: rawItems.map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        return ItineraryItem(
          id: item['id'] as String? ?? '',
          time: item['time'] as String? ?? '',
          title: item['title'] as String? ?? '',
        );
      }).toList(),
      showMessage: map['showMessage'] as bool? ?? true,
      showCountdown: map['showCountdown'] as bool? ?? true,
      showLocation: map['showLocation'] as bool? ?? true,
      showItinerary: map['showItinerary'] as bool? ?? true,
      showDressCode: map['showDressCode'] as bool? ?? true,
      fontFamily: map['fontFamily'] as String? ?? defaults.fontFamily,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? defaults.colorValue,
      backgroundUrl: map['backgroundUrl'] as String?,
    );
  }

  static Map<String, dynamic> toMap(InvitationConfig c) {
    return {
      'message': c.message.trim(),
      'dressCode': c.dressCode.trim(),
      'itinerary': [
        for (final i in c.itinerary)
          {'id': i.id, 'time': i.time, 'title': i.title.trim()},
      ],
      'showMessage': c.showMessage,
      'showCountdown': c.showCountdown,
      'showLocation': c.showLocation,
      'showItinerary': c.showItinerary,
      'showDressCode': c.showDressCode,
      'fontFamily': c.fontFamily,
      'colorValue': c.colorValue,
      'backgroundUrl': c.backgroundUrl,
    };
  }
}
