import 'package:material_ui/material_ui.dart';

class SocialButtons extends StatelessWidget {
  const SocialButtons({
    super.key,
    required this.enabled,
    required this.onGoogle,
    required this.onFacebook,
  });

  final bool enabled;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: enabled ? onGoogle : null,
          icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
          label: const Text('Continuar con Google'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onFacebook : null,
          icon: const Icon(Icons.facebook, size: 22),
          label: const Text('Continuar con Facebook'),
        ),
      ],
    );
  }
}
