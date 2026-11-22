import 'package:equatable/equatable.dart';

enum PlanId { free, basico, premium, pro }

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    this.highlighted = false,
  });

  final PlanId id;
  final String name;

  /// Precio mensual en MXN.
  final int price;
  final List<String> features;

  /// Plan recomendado (se resalta en la pantalla).
  final bool highlighted;

  bool get isFree => price == 0;

  @override
  List<Object> get props => [id, name, price, features, highlighted];
}

const kPlans = [
  SubscriptionPlan(
    id: PlanId.free,
    name: 'Gratis',
    price: 0,
    features: ['1 evento', 'Hasta 50 invitados', 'Invitación y pase QR'],
  ),
  SubscriptionPlan(
    id: PlanId.basico,
    name: 'Básico',
    price: 149,
    features: [
      '3 eventos',
      'Hasta 150 invitados',
      'Plano de mesas',
      'Recepción con QR',
    ],
  ),
  SubscriptionPlan(
    id: PlanId.premium,
    name: 'Premium',
    price: 299,
    highlighted: true,
    features: [
      'Eventos ilimitados',
      'Hasta 500 invitados',
      'Álbum compartido',
      'Todo lo del Básico',
    ],
  ),
  SubscriptionPlan(
    id: PlanId.pro,
    name: 'Pro',
    price: 599,
    features: [
      'Todo lo de Premium',
      'Invitados ilimitados',
      'Soporte prioritario',
      'Pases en Wallet (próximamente)',
    ],
  ),
];

PlanId planIdFrom(String? value) =>
    PlanId.values.firstWhere((p) => p.name == value, orElse: () => PlanId.free);

SubscriptionPlan planById(PlanId id) => kPlans.firstWhere((p) => p.id == id);
