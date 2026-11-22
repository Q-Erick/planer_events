import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> authStateChanges();
  UserModel? get currentUser;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(
    String name,
    String email,
    String password,
  );
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();
  Future<void> sendEmailVerification();
  Future<UserModel> reloadUser();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
    required FacebookAuth facebookAuth,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn,
       _facebookAuth = facebookAuth;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  /// GoogleSignIn debe inicializarse una sola vez.
  Future<void>? _googleInit;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ---------------- Estado ----------------

  @override
  Stream<UserModel?> authStateChanges() {
    // userChanges también avisa cuando cambia la foto, el nombre
    // o la verificación del correo.
    return _auth.userChanges().map(
      (user) => user == null ? null : UserModel.fromFirebase(user),
    );
  }

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebase(user);
  }

  // ---------------- Correo y contraseña ----------------

  @override
  Future<UserModel> signInWithEmail(String email, String password) {
    return _run(() async {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel.fromFirebase(cred.user!);
    });
  }

  @override
  Future<UserModel> registerWithEmail(
    String name,
    String email,
    String password,
  ) {
    return _run(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);
      await user.sendEmailVerification();
      await user.reload();

      final model = UserModel.fromFirebase(_auth.currentUser!);
      await _saveProfile(model, isNew: true);
      return model;
    });
  }

  // ---------------- Google ----------------

  @override
  Future<UserModel> signInWithGoogle() {
    return _run(() async {
      _googleInit ??= _googleSignIn.initialize();
      await _googleInit;

      final GoogleSignInAccount account;
      try {
        account = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          throw const CancelledException();
        }
        throw AuthException(
          'No se pudo iniciar sesión con Google (${e.code.name}).',
        );
      }

      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);

      final model = UserModel.fromFirebase(cred.user!);
      await _saveProfile(
        model,
        isNew: cred.additionalUserInfo?.isNewUser ?? false,
      );
      return model;
    });
  }

  // ---------------- Facebook ----------------

  @override
  Future<UserModel> signInWithFacebook() {
    return _run(() async {
      final LoginResult result;
      try {
        result = await _facebookAuth.login(
          permissions: ['email', 'public_profile'],
        );
      } catch (_) {
        throw const AuthException(
          'El inicio de sesión con Facebook aún no está disponible.',
        );
      }

      if (result.status == LoginStatus.cancelled) {
        throw const CancelledException();
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AuthException(
          result.message ?? 'No se pudo iniciar sesión con Facebook.',
        );
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final cred = await _auth.signInWithCredential(credential);

      final model = UserModel.fromFirebase(cred.user!);
      await _saveProfile(
        model,
        isNew: cred.additionalUserInfo?.isNewUser ?? false,
      );
      return model;
    });
  }

  // ---------------- Verificación y contraseña ----------------

  @override
  Future<void> sendEmailVerification() {
    return _run(() async {
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('No hay sesión activa.');
      await user.sendEmailVerification();
    });
  }

  @override
  Future<UserModel> reloadUser() {
    return _run(() async {
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('No hay sesión activa.');
      await user.reload();
      return UserModel.fromFirebase(_auth.currentUser!);
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _run(() => _auth.sendPasswordResetEmail(email: email));
  }

  @override
  Future<void> signOut() {
    return _run(() async {
      // Si falla cerrar Google o Facebook, igual cerramos Firebase.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _facebookAuth.logOut();
      } catch (_) {}
      await _auth.signOut();
    });
  }

  // ---------------- Helpers ----------------

  /// Guarda o actualiza el perfil del usuario en Firestore.
  Future<void> _saveProfile(UserModel user, {required bool isNew}) async {
    final data = user.toFirestore();
    if (isNew) {
      data['plan'] = 'free';
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Ejecuta la acción y traduce los errores de Firebase a español.
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CancelledException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Error del servidor.');
    } catch (_) {
      throw const ServerException('Ocurrió un error inesperado.');
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet.';
      case 'account-exists-with-different-credential':
        return 'Ya tienes una cuenta con este correo usando otro método de inicio de sesión.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión.';
      default:
        return 'Error de autenticación ($code).';
    }
  }
}
