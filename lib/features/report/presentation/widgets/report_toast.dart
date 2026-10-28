import 'dart:async';

import 'package:flutter/material.dart';

import '../../../search/presentation/widgets/search_toast.dart';

const reportToastDuration = Duration(milliseconds: 3200);

// Thank-you toast that outlives the closed sheet, on the screen underneath
void showReportToast(OverlayState overlay, String message) {
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastHost(message: message, onDone: entry.remove),
  );
  overlay.insert(entry);
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _timer = Timer(reportToastDuration, () {
      setState(() => _message = null);
      _timer = Timer(const Duration(milliseconds: 250), widget.onDone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay sits outside any Scaffold, so give the text a Material
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [SearchToast(message: _message)]),
    );
  }
}
