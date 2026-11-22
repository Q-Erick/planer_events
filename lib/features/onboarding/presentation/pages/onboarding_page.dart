import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/app_router.dart';
import '../../../../injection_container.dart';
import '../bloc/onboarding_cubit.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_indicator.dart';

const _slides = [
  OnboardingSlideData(
    icon: Icons.mail_outline_rounded,
    title: 'Invitaciones digitales',
    description: 'Diseña tu invitación con cuenta regresiva, ubicación, itinerario y dress code.',
  ),
  OnboardingSlideData(
    icon: Icons.table_restaurant_outlined,
    title: 'Plano de mesas',
    description:
        'Acomoda las mesas en el salón y asigna a cada invitado su lugar.',
  ),
  OnboardingSlideData(
    icon: Icons.qr_code_2_rounded,
    title: 'Pase con QR',
    description: 'Cada invitado recibe su pase. En la entrada se escanea y se le indica su mesa.',
  ),
  OnboardingSlideData(
    icon: Icons.photo_library_outlined,
    title: 'Álbum compartido',
    description:
        'Todas las fotos que tomen tus invitados, reunidas en un solo lugar.',
  ),
];

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  bool _isLast(int index) => index == _slides.length - 1;

  Future<void> _finish(BuildContext context) async {
    await context.read<OnboardingCubit>().finish();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: BlocBuilder<OnboardingCubit, int>(
              builder: (context, index) {
                return Column(
                  children: [
                    // Botón "Saltar" (se oculta en la última página)
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _isLast(index)
                            ? null
                            : TextButton(
                                onPressed: () => _finish(context),
                                child: const Text('Saltar'),
                              ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: cubit.pageController,
                        itemCount: _slides.length,
                        onPageChanged: cubit.onPageChanged,
                        itemBuilder: (_, i) =>
                            OnboardingSlide(data: _slides[i]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        children: [
                          PageIndicator(count: _slides.length, current: index),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: _isLast(index)
                                ? () => _finish(context)
                                : cubit.next,
                            child: Text(
                              _isLast(index) ? 'Comenzar' : 'Siguiente',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
