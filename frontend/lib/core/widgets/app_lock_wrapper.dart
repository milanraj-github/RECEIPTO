import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/app_lock_provider.dart';
import 'package:receipto/features/auth/presentation/screens/app_lock_screen.dart';

class AppLockWrapper extends ConsumerWidget {
  final Widget child;

  const AppLockWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);

    return Stack(
      children: [
        child,
        if (lockState.isLocked)
          const Positioned.fill(
            child: AppLockScreen(),
          ),
      ],
    );
  }
}
