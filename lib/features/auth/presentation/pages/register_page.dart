import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/form_status.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../injection_container.dart';
import '../bloc/register_cubit.dart';
import '../widgets/auth_layout.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterCubit>(),
      child: BlocListener<RegisterCubit, RegisterState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status && curr.status == FormStatus.failure,
        listener: (context, state) => showAppSnackBar(
          context,
          state.errorMessage ?? 'Ocurrió un error.',
          isError: true,
        ),
        child: const _RegisterForm(),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();

        Widget visibilityButton() => IconButton(
          onPressed: cubit.togglePasswordVisibility,
          icon: Icon(
            state.obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        );

        return AuthLayout(
          showBack: true,
          children: [
            const AuthHeader(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Crea tu cuenta',
              subtitle: 'Empieza a planear tu evento en minutos',
            ),
            TextField(
              onChanged: cubit.nameChanged,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: 'Nombre',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: state.nameError,
              ),
            ),
            const SizedBox(height: 16),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: state.passwordError,
                suffixIcon: visibilityButton(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: cubit.confirmPasswordChanged,
              obscureText: state.obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => cubit.submit(),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: state.confirmError,
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Crear cuenta',
              isLoading: state.isLoading,
              onPressed: cubit.submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tienes cuenta?'),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
