import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/app_toast.dart';

// Self-hiding toast for a notifier whose state carries a message
mixin ToastHost<T> on Notifier<T> {
  Timer? _toastTimer;

  T withToast(T state, String? message);

  // Call from build so the timer stops with the notifier
  void bindToast() => ref.onDispose(() => _toastTimer?.cancel());

  void toast(String message) {
    state = withToast(state, message);
    scheduleToastHide();
  }

  void scheduleToastHide() {
    _toastTimer?.cancel();
    _toastTimer = Timer(appToastDuration, () {
      state = withToast(state, null);
    });
  }
}
