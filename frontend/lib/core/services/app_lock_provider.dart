import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/app_lock_service.dart';

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final DateTime? lastBackgroundTime;

  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.isBiometricEnabled,
    required this.isBiometricAvailable,
    required this.isPinSet,
    this.lastBackgroundTime,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isPinSet,
    DateTime? lastBackgroundTime,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isPinSet: isPinSet ?? this.isPinSet,
      lastBackgroundTime: lastBackgroundTime ?? this.lastBackgroundTime,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> with WidgetsBindingObserver {
  final AppLockService _service;

  AppLockNotifier(this._service)
      : super(const AppLockState(
          isEnabled: false,
          isLocked: false,
          isBiometricEnabled: false,
          isBiometricAvailable: false,
          isPinSet: false,
        )) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final enabled = await _service.isAppLockEnabled();
      final pinSet = await _service.isPinSet();
      final bioEnabled = await _service.isBiometricEnabled();
      final bioAvailable = await _service.isBiometricsAvailable();

      if (!enabled) {
        // App Lock is disabled -> never lock on fresh install or launch!
        state = AppLockState(
          isEnabled: false,
          isLocked: false,
          isBiometricEnabled: bioEnabled,
          isBiometricAvailable: bioAvailable,
          isPinSet: pinSet,
        );
      } else if (enabled && pinSet) {
        // App Lock enabled AND valid PIN hash exists -> show lock screen!
        state = AppLockState(
          isEnabled: true,
          isLocked: true,
          isBiometricEnabled: bioEnabled,
          isBiometricAvailable: bioAvailable,
          isPinSet: true,
        );
      } else {
        // CORRUPTED / INVALID STATE: app_lock_enabled is true BUT pin_hash is missing!
        // Automatically purge corrupted keys and do NOT lock the user out!
        await _service.resetAppLock();
        state = AppLockState(
          isEnabled: false,
          isLocked: false,
          isBiometricEnabled: false,
          isBiometricAvailable: bioAvailable,
          isPinSet: false,
        );
      }
    } catch (e) {
      // Emergency fallback on storage error: unlock user
      state = const AppLockState(
        isEnabled: false,
        isLocked: false,
        isBiometricEnabled: false,
        isBiometricAvailable: false,
        isPinSet: false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      this.state = this.state.copyWith(lastBackgroundTime: DateTime.now());
    } else if (state == AppLifecycleState.resumed) {
      // Require enabled == true AND pinSet == true before locking on background resume (>30s)
      if (this.state.isEnabled && this.state.isPinSet && this.state.lastBackgroundTime != null) {
        final elapsed = DateTime.now().difference(this.state.lastBackgroundTime!);
        if (elapsed > const Duration(seconds: 30)) {
          this.state = this.state.copyWith(isLocked: true);
        }
      }
    }
  }

  /// Unlocks the app.
  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  /// Locks the app manually if enabled.
  void lock() {
    if (state.isEnabled && state.isPinSet) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// Refreshes state from secure storage.
  Future<void> refreshState() async {
    await _init();
  }

  /// Sets App Lock enabled state.
  Future<void> setAppLockEnabled(bool enabled) async {
    await _service.setAppLockEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
  }

  /// Sets Biometric unlock enabled state.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _service.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  /// Saves new custom PIN hash.
  Future<void> setCustomPin(String pin) async {
    await _service.setCustomPin(pin);
    state = state.copyWith(isPinSet: true);
  }

  /// Purges all app lock keys.
  Future<void> resetAppLock() async {
    await _service.resetAppLock();
    state = const AppLockState(
      isEnabled: false,
      isLocked: false,
      isBiometricEnabled: false,
      isBiometricAvailable: false,
      isPinSet: false,
    );
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return AppLockNotifier(service);
});
