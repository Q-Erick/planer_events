import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../bloc/forgot_password_cubit.dart';
import '../widgets/auth_layout.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status && curr.status == FormStatus.failure,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? 'Ocurrió un error.',
          isError: true,
        ),
        builder: (context, state) {
          final cubit = context.read<ForgotPasswordCubit>();

          // Pantalla de confirmación
          if (state.status == FormStatus.success) {
            return AuthLayout(
              showBack: true,
              children: [
                AuthHeader(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Revisa tu correo',
                  subtitle:
                      'Si existe una cuenta con ${state.email.trim()}, '
                      'te enviamos un enlace para crear una nueva contraseña.',
                ),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            );
          }

          return AuthLayout(
            showBack: true,
            children: [
              const AuthHeader(
                icon: Icons.lock_reset_rounded,
                title: 'Recupera tu contraseña',
                subtitle: 'Escribe tu correo y te enviaremos un enlace para restablecerla.',
              ),
              TextField(
                onChanged: cubit.emailChanged,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => cubit.submit(),
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: state.emailError,
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Enviar enlace',
                isLoading: state.isLoading,
                onPressed: cubit.submit,
              ),
            ],
          );
        },
      ),
    );
  }
}
