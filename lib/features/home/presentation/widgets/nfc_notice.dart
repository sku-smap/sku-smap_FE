import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../campus/state/nfc_link_provider.dart';
import '../../../report/presentation/widgets/applied_notice.dart';

// Toast for each tag link; at launch it waits for the splash to finish
class NfcNotice extends ConsumerStatefulWidget {
  const NfcNotice({super.key});

  @override
  ConsumerState<NfcNotice> createState() => _NfcNoticeState();
}

class _NfcNoticeState extends ConsumerState<NfcNotice> {
  String? _message;
  int? _shown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.listenManual(nfcNoticeProvider, (_, next) {
      if (next == null || next.seq == _shown) return;
      _shown = next.seq;
      _timer?.cancel();
      _timer = Timer(
        next.seq == 0 ? ReportAppliedNotice.delay : Duration.zero,
        () => _show(next.text),
      );
    }, fireImmediately: true);
  }

  void _show(String text) {
    if (!mounted) return;
    setState(() => _message = text);
    _timer = Timer(appToastDuration, () {
      if (mounted) setState(() => _message = null);
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
