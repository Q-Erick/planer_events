import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../bloc/checkin_cubit.dart';
import '../widgets/checkin_widgets.dart';

class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CheckInCubit>()
        ..watch(eventId)
        ..unlock(),
      child: const _CheckInView(),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView();

  Future<void> _search(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final guest = await showGuestSearchSheet(context, cubit.state.guests);
    if (guest != null) cubit.selectGuest(guest);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CheckInCubit>();

    return BlocConsumer<CheckInCubit, CheckInState>(
      listenWhen: (prev, curr) =>
          curr.message != null && prev.message != curr.message,
      listener: (context, state) =>
          showAppSnackBar(context, state.message!, isError: state.isError),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Recepción')),
          body: !state.isUnlocked
              ? LockedView(
                  isAuthenticating: state.isAuthenticating,
                  error: state.authError,
                  onUnlock: cubit.unlock,
                )
              : Column(
                  children: [
                    // Contador de llegadas
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.how_to_reg_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Llegaron ${state.arrivedPasses} de '
                            '${state.totalPasses} lugares',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          // Cámara
                          Positioned.fill(
                            child: MobileScanner(
                              controller: cubit.scannerController,
                              onDetect: (capture) => cubit.onDetect(
                                capture.barcodes.isEmpty
                                    ? null
                                    : capture.barcodes.first.rawValue,
                              ),
                            ),
                          ),
                          // Marco guía
                          Center(
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          // Resultado
                          if (state.selectedGuest != null)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                ),
                                child: CheckInResultCard(
                                  guest: state.selectedGuest!,
                                  seats: state.selectedSeats,
                                  isSaving: state.isSaving,
                                  onConfirm: cubit.confirmCheckIn,
                                  onCancel: cubit.dismiss,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: () => _search(context),
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar por nombre'),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
