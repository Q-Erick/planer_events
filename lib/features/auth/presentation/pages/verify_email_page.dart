import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/verify_email_cubit.dart';
import '../widgets/auth_layout.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select(
      (AuthBloc bloc) => bloc.state.user?.email ?? '',
    );

    return BlocProvider(
      create: (_) => sl<VerifyEmailCubit>(),
      child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
        listener: (context, state) {
          // Correo verificado: actualizamos la sesión y el router
          // nos lleva al inicio automáticamente.
          if (state.verifiedUser != null) {
            context.read<AuthBloc>().add(
              AuthUserRefreshed(state.verifiedUser!),
            );
            return;
          }
          if (state.message != null) {
            showAppSnackBar(context, state.message!, isError: state.isError);
          }
        },
        builder: (context, state) {
          final cubit = context.read<VerifyEmailCubit>();

          return AuthLayout(
            children: [
              AuthHeader(
                icon: Icons.mark_email_unread_outlined,
                title: 'Verifica tu correo',
                subtitle:
                    'Enviamos un enlace de verificación a $email. '
                    'Ábrelo para activar tu cuenta; esta pantalla se '
                    'actualizará sola. Revisa también tu carpeta de spam.',
              ),
              LoadingButton(
                label: 'Ya lo verifiqué',
                isLoading: state.isChecking,
                onPressed: cubit.check,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.cooldown > 0 || state.isSending
                    ? null
                    : cubit.resend,
                child: Text(
                  state.cooldown > 0
                      ? 'Reenviar en ${state.cooldown} s'
                      : 'Reenviar correo',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                child: const Text('Usar otra cuenta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
