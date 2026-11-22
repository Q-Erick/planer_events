import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'core/theme/theme_cubit.dart';
import 'features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'features/onboarding/domain/repositories/onboarding_repository.dart';
import 'features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'features/auth/presentation/bloc/login_cubit.dart';
import 'features/auth/presentation/bloc/register_cubit.dart';
import 'features/auth/presentation/bloc/verify_email_cubit.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/profile_usecases.dart';
import 'features/profile/presentation/bloc/profile_cubit.dart';
import 'features/events/data/datasources/event_remote_datasource.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/domain/usecases/event_usecases.dart';
import 'features/events/presentation/bloc/event_detail_cubit.dart';
import 'features/events/presentation/bloc/event_form_cubit.dart';
import 'features/events/presentation/bloc/events_list_cubit.dart';
import 'features/guests/data/datasources/guest_remote_datasource.dart';
import 'features/guests/data/repositories/guest_repository_impl.dart';
import 'features/guests/domain/repositories/guest_repository.dart';
import 'features/guests/domain/usecases/guest_usecases.dart';
import 'features/guests/presentation/bloc/guest_form_cubit.dart';
import 'features/guests/presentation/bloc/guests_cubit.dart';
import 'features/seating/data/datasources/seating_remote_datasource.dart';
import 'features/seating/data/repositories/seating_repository_impl.dart';
import 'features/seating/domain/repositories/seating_repository.dart';
import 'features/seating/domain/usecases/seating_usecases.dart';
import 'features/seating/presentation/bloc/seating_cubit.dart';

final sl = GetIt.instance; // sl = service locator

Future<void> init() async {
  // ---------- Externos ----------
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
  sl.registerLazySingleton<FacebookAuth>(() => FacebookAuth.instance);
  sl.registerLazySingleton<ImagePicker>(() => ImagePicker());

  // Correos de verificación y recuperación en español
  await FirebaseAuth.instance.setLanguageCode('es');

  // ---------- Core ----------
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));

  // ---------- Features ----------
  // Onboarding
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => IsOnboardingCompleted(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));
  sl.registerFactory(() => OnboardingCubit(sl()));

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      auth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
      facebookAuth: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAuthStateChanges(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => RegisterWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithFacebook(sl()));
  sl.registerLazySingleton(() => SendEmailVerification(sl()));
  sl.registerLazySingleton(() => ReloadUser(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // AuthBloc es global (uno solo para toda la app)
  sl.registerLazySingleton(
    () =>
        AuthBloc(getAuthStateChanges: sl(), getCurrentUser: sl(), signOut: sl())
          ..add(const AuthSubscriptionRequested()),
  );

  // Cubits de formularios (uno nuevo cada vez que se abre la pantalla)
  sl.registerFactory(
    () => LoginCubit(
      signInWithEmail: sl(),
      signInWithGoogle: sl(),
      signInWithFacebook: sl(),
    ),
  );
  sl.registerFactory(() => RegisterCubit(registerWithEmail: sl()));
  sl.registerFactory(() => ForgotPasswordCubit(sendPasswordReset: sl()));
  sl.registerFactory(
    () => VerifyEmailCubit(reloadUser: sl(), sendEmailVerification: sl()),
  );

  // Perfil
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () =>
        ProfileRemoteDataSourceImpl(auth: sl(), storage: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => UpdateProfilePhoto(sl()));
  sl.registerLazySingleton(() => UpdateDisplayName(sl()));
  sl.registerFactory(
    () => ProfileCubit(
      updateProfilePhoto: sl(),
      updateDisplayName: sl(),
      imagePicker: sl(),
    ),
  );

  // Eventos
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<EventRepository>(() => EventRepositoryImpl(sl()));
  sl.registerLazySingleton(() => WatchHostEvents(sl()));
  sl.registerLazySingleton(() => WatchEvent(sl()));
  sl.registerLazySingleton(() => CreateEvent(sl()));
  sl.registerLazySingleton(() => UpdateEvent(sl()));
  sl.registerLazySingleton(() => DeleteEvent(sl()));
  sl.registerFactory(() => EventsListCubit(sl()));
  sl.registerFactory(
    () => EventDetailCubit(watchEvent: sl(), deleteEvent: sl()),
  );
  sl.registerFactory(
    () =>
        EventFormCubit(watchEvent: sl(), createEvent: sl(), updateEvent: sl()),
  );

  // Invitados
  sl.registerLazySingleton<GuestRemoteDataSource>(
    () => GuestRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GuestRepository>(() => GuestRepositoryImpl(sl()));
  sl.registerLazySingleton(() => WatchGuests(sl()));
  sl.registerLazySingleton(() => AddGuest(sl()));
  sl.registerLazySingleton(() => UpdateGuest(sl()));
  sl.registerLazySingleton(() => DeleteGuest(sl()));
  sl.registerFactory(
    () => GuestsCubit(
      watchGuests: sl(),
      watchEvent: sl(),
      watchTables: sl(),
      deleteGuest: sl(),
      releaseGuestSeats: sl(),
    ),
  );
  sl.registerFactory(() => GuestFormCubit(addGuest: sl(), updateGuest: sl()));

  // Plano de mesas
  sl.registerLazySingleton<SeatingRemoteDataSource>(
    () => SeatingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SeatingRepository>(
    () => SeatingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => WatchTables(sl()));
  sl.registerLazySingleton(() => WatchSeatsPerTable(sl()));
  sl.registerLazySingleton(() => SetSeatsPerTable(sl()));
  sl.registerLazySingleton(() => AddTable(sl()));
  sl.registerLazySingleton(() => MoveTable(sl()));
  sl.registerLazySingleton(() => ChangeTableSeats(sl()));
  sl.registerLazySingleton(() => ChangeTableShape(sl()));
  sl.registerLazySingleton(() => DeleteTable(sl()));
  sl.registerLazySingleton(() => AssignGuest(sl()));
  sl.registerLazySingleton(() => ReleaseSeat(sl()));
  sl.registerLazySingleton(() => ReleaseGuestSeats(sl()));
  sl.registerFactory(
    () => SeatingCubit(
      watchTables: sl(),
      watchSeatsPerTable: sl(),
      watchGuests: sl(),
      setSeatsPerTable: sl(),
      addTable: sl(),
      moveTable: sl(),
      changeTableSeats: sl(),
      changeTableShape: sl(),
      deleteTable: sl(),
      assignGuest: sl(),
      releaseSeat: sl(),
      releaseGuestSeats: sl(),
    ),
  );
}
