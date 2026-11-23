import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.provider,
    super.displayName,
    super.photoUrl,
    super.emailVerified,
    super.isAnonymous,
  });

  /// Crea el modelo a partir del usuario de Firebase Auth.
  factory UserModel.fromFirebase(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      provider: _providerFrom(user),
      isAnonymous: user.isAnonymous,
    );
  }

  static AuthProviderType _providerFrom(User user) {
    final ids = user.providerData.map((p) => p.providerId);
    if (ids.contains('google.com')) return AuthProviderType.google;
    if (ids.contains('facebook.com')) return AuthProviderType.facebook;
    return AuthProviderType.email;
  }

  /// Datos que se guardan en la colección `users` de Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': name,
      'photoUrl': photoUrl,
      'provider': provider.name,
    };
  }
}
