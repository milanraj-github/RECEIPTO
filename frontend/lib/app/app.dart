import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/app/config/routes.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/app_lock_wrapper.dart';

class ReceiptoApp extends ConsumerWidget {
  const ReceiptoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Receipto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return AppLockWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
