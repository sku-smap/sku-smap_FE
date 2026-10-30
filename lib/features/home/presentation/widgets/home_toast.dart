import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../state/home_notice.dart';

// Shows the latest home notice for a few seconds; a newer one cuts it short
class HomeToast extends ConsumerStatefulWidget {
  const HomeToast({super.key});

  static const duration = Duration(seconds: 5);

  @override
  ConsumerState<HomeToast> createState() => _HomeToastState();
}

class _HomeToastState extends ConsumerState<HomeToast> {
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.listenManual(homeNoticeProvider, (_, next) {
      if (next == null) return;
      _timer?.cancel();
      setState(() => _message = next.text);
      _timer = Timer(HomeToast.duration, () {
        if (mounted) setState(() => _message = null);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppToast(message: _message);
}
