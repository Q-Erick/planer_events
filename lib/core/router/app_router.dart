import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../injection_container.dart';
import '../widgets/user_avatar.dart';
import 'go_router_refresh_stream.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const profile = '/profile';

  /// Rutas que solo se ven sin sesión.
  static const authRoutes = {login, register, forgotPassword};
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    // Vuelve a evaluar las redirecciones cada vez que cambia la sesión
    refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _TemporaryHomePage(),
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // 1. Primero la introducción
    if (!sl<IsOnboardingCompleted>()()) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }

    final auth = sl<AuthBloc>().state;
    final isAuthRoute = AppRoutes.authRoutes.contains(location);

    // 2. Sin sesión → login (o registro / recuperar contraseña)
    if (!auth.isAuthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    // 3. Con sesión pero correo sin verificar
    if (auth.user!.needsEmailVerification) {
      return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
    }

    // 4. Con sesión y verificado: fuera de las pantallas de acceso
    if (isAuthRoute ||
        location == AppRoutes.verifyEmail ||
        location == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    return null;
  }
}

/// Página temporal de inicio. Se reemplaza por el dashboard más adelante.
class _TemporaryHomePage extends StatelessWidget {
  const _TemporaryHomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planer Events'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(AppRoutes.profile),
                child: UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 18,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user != null)
                UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 48,
                ),
              const SizedBox(height: 16),
              Text(
                'Hola, ${user?.name ?? ''}',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí aparecerán tus eventos.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
