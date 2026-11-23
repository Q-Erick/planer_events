import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../bloc/login_cubit.dart';
import '../widgets/auth_layout.dart';
import '../widgets/social_buttons.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status && curr.status == FormStatus.failure,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? 'Ocurrió un error.',
          isError: true,
        ),
        child: const _LoginForm(),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();

        return AuthLayout(
          children: [
            const AuthHeader(
              icon: Icons.celebration_outlined,
              title: 'Bienvenido',
              subtitle: 'Inicia sesión para organizar tu evento',
            ),
            TextField(
              onChanged: cubit.emailChanged,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: state.emailError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: cubit.passwordChanged,
              obscureText: state.obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => cubit.submit(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: state.passwordError,
                suffixIcon: IconButton(
                  onPressed: cubit.togglePasswordVisibility,
                  icon: Icon(
                    state.obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 8),
            LoadingButton(
              label: 'Iniciar sesión',
              isLoading: state.isLoading,
              onPressed: cubit.submit,
            ),
            const SizedBox(height: 24),
            SocialButtons(
              enabled: !state.isLoading,
              onGoogle: cubit.signInWithGoogle,
              onFacebook: cubit.signInWithFacebook,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tienes cuenta?'),
                TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Regístrate'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.guestAccess),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Tengo una invitación'),
            ),
          ],
        );
      },
    );
  }
}
