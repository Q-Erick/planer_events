import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_cubit.dart';
import '../../../../core/router/app_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>(),
      child: BlocListener<ProfileCubit, ProfileState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) =>
            showAppSnackBar(context, state.message!, isError: state.isError),
        child: const _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  String _providerLabel(AuthProviderType provider) => switch (provider) {
    AuthProviderType.email => 'Correo electrónico',
    AuthProviderType.google => 'Google',
    AuthProviderType.facebook => 'Facebook',
  };

  IconData _providerIcon(AuthProviderType provider) => switch (provider) {
    AuthProviderType.email => Icons.email_outlined,
    AuthProviderType.google => Icons.g_mobiledata_rounded,
    AuthProviderType.facebook => Icons.facebook,
  };

  @override
  Widget build(BuildContext context) {
    // Se reconstruye solo cuando cambia el usuario (foto, nombre, etc.)
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final profile = context.watch<ProfileCubit>().state;
    final theme = Theme.of(context);

    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _AvatarSection(
                  user: user,
                  isUploading: profile.isUploadingPhoto,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(user.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(_providerIcon(user.provider), size: 18),
                  label: Text(_providerLabel(user.provider)),
                ),
                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Nombre'),
                        subtitle: Text(user.name),
                        trailing: profile.isSavingName
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit_outlined),
                        onTap: profile.isSavingName
                            ? null
                            : () => _editName(context, user.name),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Correo'),
                        subtitle: Text(user.email),
                        trailing: Icon(
                          Icons.verified,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: const Text('Foto de perfil'),
                        subtitle: Text(
                          user.canEditPhoto
                              ? 'Toca el ícono de la cámara para cambiarla.'
                              : 'Se sincroniza con tu cuenta de '
                                    '${_providerLabel(user.provider)}.',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: const Text('Planes y suscripción'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.plans),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Notificaciones'),
                        subtitle: const Text('Temas y avisos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      const Divider(height: 1),
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, _) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return SwitchListTile(
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Modo oscuro'),
                            value: isDark,
                            onChanged: (value) =>
                                context.read<ThemeCubit>().setTheme(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => context.read<AuthBloc>().add(
                    const AuthSignOutRequested(),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, String current) async {
    final cubit = context.read<ProfileCubit>();
    var value = current;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextFormField(
          initialValue: current,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => value = v,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(dialogContext, value),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result.trim() != current) {
      await cubit.changeName(result);
    }
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user, required this.isUploading});

  final UserEntity user;
  final bool isUploading;

  Future<void> _choosePhoto(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) await cubit.changePhoto(user, source);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 60),
        if (isUploading)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        // El botón de cámara solo aparece en cuentas de correo
        if (user.canEditPhoto && !isUploading)
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              onPressed: () => _choosePhoto(context),
              icon: const Icon(Icons.photo_camera),
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
