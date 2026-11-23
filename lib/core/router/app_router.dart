import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/events/presentation/pages/event_form_page.dart';
import '../../features/events/presentation/pages/home_page.dart';
import '../../features/events/presentation/pages/location_picker_page.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/guests/presentation/pages/guests_page.dart';
import '../../features/seating/presentation/pages/seating_page.dart';
import '../../features/checkin/presentation/pages/checkin_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/subscription/domain/entities/subscription_plan.dart';
import '../../features/subscription/presentation/pages/checkout_page.dart';
import '../../features/subscription/presentation/pages/plans_page.dart';
import '../../features/album/presentation/pages/album_page.dart';
import '../../features/invitation/presentation/pages/invitation_editor_page.dart';
import '../../features/invitation/presentation/pages/guest_access_page.dart';
import '../../features/invitation/presentation/pages/guest_invitation_page.dart';
import '../../injection_container.dart';
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
  static const newEvent = '/events/new';
  static const locationPicker = '/location-picker';
  static const notifications = '/notifications';
  static const plans = '/plans';
  static const guestAccess = '/guest-access';

  static String eventDetail(String id) => '/events/$id';
  static String eventEdit(String id) => '/events/$id/edit';
  static String guests(String eventId) => '/events/$eventId/guests';
  static String seating(String eventId) => '/events/$eventId/seating';
  static String checkIn(String eventId) => '/events/$eventId/checkin';
  static String album(String eventId) => '/events/$eventId/album';
  static String invitation(String eventId) => '/events/$eventId/invitation';
  static String checkout(String planId) => '/plans/checkout/$planId';
  static String guestInvitation(String eventId, String guestId) =>
      '/i/$eventId/$guestId';

  static bool isGuestRoute(String location) =>
      location.startsWith('/i/') || location == guestAccess;

  /// Rutas que solo se ven sin sesión.
  static const authRoutes = {login, register, forgotPassword};
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
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
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      // Importante: '/events/new' va ANTES que '/events/:id'
      GoRoute(
        path: AppRoutes.newEvent,
        builder: (context, state) => const EventFormPage(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) =>
            EventDetailPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/edit',
        builder: (context, state) =>
            EventFormPage(eventId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/events/:id/guests',
        builder: (context, state) =>
            GuestsPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/seating',
        builder: (context, state) =>
            SeatingPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/checkin',
        builder: (context, state) =>
            CheckInPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/album',
        builder: (context, state) =>
            AlbumPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/invitation',
        builder: (context, state) =>
            InvitationEditorPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.locationPicker,
        builder: (context, state) =>
            LocationPickerPage(initial: state.extra as LatLng?),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.plans,
        builder: (context, state) => const PlansPage(),
      ),
      GoRoute(
        path: '/plans/checkout/:plan',
        builder: (context, state) =>
            CheckoutPage(planId: planIdFrom(state.pathParameters['plan'])),
      ),
      GoRoute(
        path: AppRoutes.guestAccess,
        builder: (context, state) => const GuestAccessPage(),
      ),
      GoRoute(
        path: '/i/:eventId/:guestId',
        builder: (context, state) => GuestInvitationPage(
          eventId: state.pathParameters['eventId']!,
          guestId: state.pathParameters['guestId']!,
        ),
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // 0. Las rutas del invitado no piden onboarding ni cuenta
    if (AppRoutes.isGuestRoute(location)) return null;

    // 1. Primero la introducción
    if (!sl<IsOnboardingCompleted>()()) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }

    final auth = sl<AuthBloc>().state;
    final user = auth.user;
    final isAuthRoute = AppRoutes.authRoutes.contains(location);

    // 2. Sin sesión (o invitado anónimo fuera de su invitación)
    final hasAccount = auth.isAuthenticated && !(user?.isAnonymous ?? false);
    if (!hasAccount) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    // 3. Correo sin verificar
    if (user!.needsEmailVerification) {
      return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
    }

    // 4. Sesión completa: fuera de las pantallas de acceso
    if (isAuthRoute ||
        location == AppRoutes.verifyEmail ||
        location == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    return null;
  }
}
