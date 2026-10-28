import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../search/presentation/widgets/search_toast.dart';
import '../../state/report_providers.dart';
import 'report_toast.dart';

// Shortly after launch, thank the user once for reports that were applied
class ReportAppliedNotice extends ConsumerStatefulWidget {
  const ReportAppliedNotice({super.key});

  static const delay = Duration(seconds: 3);

  @override
  ConsumerState<ReportAppliedNotice> createState() =>
      _ReportAppliedNoticeState();
}

class _ReportAppliedNoticeState extends ConsumerState<ReportAppliedNotice> {
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(ReportAppliedNotice.delay, _check);
  }

  Future<void> _check() async {
    final message = await ref.read(appliedNoticeProvider.future);
    if (!mounted || message == null) return;
    setState(() => _message = message);
    _timer = Timer(reportToastDuration, () => setState(() => _message = null));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchToast(message: _message);
}
