import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Guarda el punto que el usuario tocó en el mapa.
class LocationPickerCubit extends Cubit<LatLng?> {
  LocationPickerCubit(super.initial);

  void select(LatLng position) => emit(position);
}
