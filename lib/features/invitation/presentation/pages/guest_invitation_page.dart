import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/guest_view_cubit.dart';
import '../widgets/invitation_view.dart';

class GuestInvitationPage extends StatelessWidget {
  const GuestInvitationPage({
    super.key,
    required this.eventId,
    required this.guestId,
  });

  final String eventId;
  final String guestId;

  @override
  Widget build(BuildContext context) {
    final isAnonymous = context.select(
      (AuthBloc b) => b.state.user?.isAnonymous ?? true,
    );

    return BlocProvider(
      create: (_) => sl<GuestViewCubit>()..start(eventId, guestId),
      child: BlocConsumer<GuestViewCubit, GuestViewState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) =>
            showAppSnackBar(context, state.message!, isError: state.isError),
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tu invitación'),
              actions: [
                if (isAnonymous)
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        const AuthSignOutRequested(),
                      );
                      context.go(AppRoutes.login);
                    },
                    child: const Text('Salir'),
                  ),
              ],
            ),
            body: () {
              if (state.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_lock_outlined, size: 72),
                        const SizedBox(height: 16),
                        Text(state.error!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: InvitationView(
                      event: state.event!,
                      config: state.config!,
                      footer: _GuestPass(state: state),
                    ),
                  ),
                ),
              );
            }(),
          );
        },
      ),
    );
  }
}

/// Pase del invitado: QR, mesa y cámara.
class _GuestPass extends StatelessWidget {
  const _GuestPass({required this.state});

  final GuestViewState state;

  @override
  Widget build(BuildContext context) {
    final guest = state.guest!;
    final event = state.event!;
    final accent = Color(state.config!.colorValue);
    final cubit = context.read<GuestViewCubit>();
    const dark = TextStyle(color: Color(0xFF2B2B2B));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TU PASE',
            style: TextStyle(
              color: accent,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guest.name,
            textAlign: TextAlign.center,
            style: dark.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            guest.passes == 1 ? '1 lugar' : '${guest.passes} lugares',
            style: dark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: guest.qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text('Muéstralo en la entrada.', style: dark.copyWith(fontSize: 13)),
          if (state.seats.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final s in state.seats)
              Text(
                'Mesa ${s.tableNumber} · '
                '${s.seats.length == 1 ? 'silla' : 'sillas'} ${s.seats.join(', ')}',
                style: TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
          if (guest.checkedIn) ...[
            const SizedBox(height: 12),
            Chip(
              avatar: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Llegada registrada'),
              backgroundColor: Colors.green.withValues(alpha: 0.1),
            ),
          ],
          const Divider(height: 32),
          // ---------- Cámara del evento ----------
          Text(
            'Comparte tus fotos',
            style: dark.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!event.isToday)
            Text(
              'La cámara para compartir fotos se activa el día del evento.',
              textAlign: TextAlign.center,
              style: dark,
            )
          else ...[
            if (state.isUploading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: state.isUploading
                        ? null
                        : () => cubit.addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isUploading
                        ? null
                        : () => cubit.addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
