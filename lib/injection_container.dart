import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
}
