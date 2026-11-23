import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/widgets/auth_layout.dart';
import '../../../checkin/domain/entities/qr_pass.dart';

class _AccessState extends Equatable {
  const _AccessState({this.code = '', this.error});
  final String code;
  final String? error;

  @override
  List<Object?> get props => [code, error];
}

class _AccessCubit extends Cubit<_AccessState> {
  _AccessCubit() : super(const _AccessState());

  bool _done = false;

  void codeChanged(String v) => emit(_AccessState(code: v));

  /// Devuelve el pase si el código es válido (solo una vez).
  QrPass? submit(String? raw) {
    if (_done) return null;
    final pass = QrPass.parse(raw);
    if (pass == null) {
      emit(
        _AccessState(
          code: state.code,
          error: 'Ese código no es una invitación válida.',
        ),
      );
      return null;
    }
    _done = true;
    return pass;
  }
}

class GuestAccessPage extends StatelessWidget {
  const GuestAccessPage({super.key});

  void _open(BuildContext context, String? raw) {
    final pass = context.read<_AccessCubit>().submit(raw);
    if (pass != null) {
      context.go(AppRoutes.guestInvitation(pass.eventId, pass.guestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _AccessCubit(),
      child: BlocBuilder<_AccessCubit, _AccessState>(
        builder: (context, state) {
          return AuthLayout(
            showBack: true,
            children: [
              const AuthHeader(
                icon: Icons.qr_code_scanner,
                title: 'Abre tu invitación',
                subtitle:
                    'Escanea el código QR de tu pase o pega el código '
                    'que te enviaron.',
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: MobileScanner(
                    onDetect: (capture) => _open(
                      context,
                      capture.barcodes.isEmpty
                          ? null
                          : capture.barcodes.first.rawValue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: context.read<_AccessCubit>().codeChanged,
                onSubmitted: (v) => _open(context, v),
                decoration: InputDecoration(
                  labelText: 'Código de invitación',
                  hintText: 'planer:...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _open(context, state.code),
                child: const Text('Abrir invitación'),
              ),
            ],
          );
        },
      ),
    );
  }
}
