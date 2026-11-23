import 'package:equatable/equatable.dart';

enum AuthProviderType { email, google, facebook }

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.provider,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.isAnonymous = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final AuthProviderType provider;

  /// Invitado que abrió su invitación sin crear cuenta.
  final bool isAnonymous;

  bool get canEditPhoto => provider == AuthProviderType.email && !isAnonymous;

  bool get needsEmailVerification =>
      !isAnonymous && provider == AuthProviderType.email && !emailVerified;

  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Invitado';
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    emailVerified,
    provider,
    isAnonymous,
  ];
}
