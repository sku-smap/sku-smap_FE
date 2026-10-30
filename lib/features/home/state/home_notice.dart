import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef HomeNotice = ({int seq, String text});

// A message for the home screen sent from a screen that is closing; each new
// one replaces the last
class HomeNoticeController extends Notifier<HomeNotice?> {
  @override
  HomeNotice? build() => null;

  void show(String text) => state = (seq: (state?.seq ?? 0) + 1, text: text);
}

final homeNoticeProvider = NotifierProvider<HomeNoticeController, HomeNotice?>(
  HomeNoticeController.new,
);
