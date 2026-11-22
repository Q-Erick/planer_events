import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/location_picker_cubit.dart';

class LocationPickerPage extends StatelessWidget {
  const LocationPickerPage({super.key, this.initial});

  final LatLng? initial;

  static const _defaultCenter = LatLng(20.5235, -100.8157); // Celaya

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocationPickerCubit(initial),
      child: Scaffold(
        appBar: AppBar(title: const Text('Ubicación del evento')),
        body: BlocBuilder<LocationPickerCubit, LatLng?>(
          builder: (context, selected) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initial ?? _defaultCenter,
                    zoom: initial != null ? 16 : 13,
                  ),
                  onTap: context.read<LocationPickerCubit>().select,
                  markers: {
                    if (selected != null)
                      Marker(
                        markerId: const MarkerId('venue'),
                        position: selected,
                      ),
                  },
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // Instrucción
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        selected == null
                            ? 'Toca el mapa para marcar el lugar del evento.'
                            : 'Puedes tocar otro punto para moverlo.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Confirmar
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    child: FilledButton.icon(
                      onPressed: selected == null
                          ? null
                          : () => context.pop(selected),
                      icon: const Icon(Icons.check),
                      label: const Text('Usar esta ubicación'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
