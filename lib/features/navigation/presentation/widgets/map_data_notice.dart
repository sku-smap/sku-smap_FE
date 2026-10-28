import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../campus/state/node_providers.dart';
import '../navigation_tokens.dart';
import 'viewer_notice.dart';

// Viewer screens wait here until the campus map arrives, or offer a retry
class MapDataNotice extends ConsumerWidget {
  const MapDataNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(campusMapProvider).error;
    return Scaffold(
      backgroundColor: NavColors.photoBg,
      body: error == null
          ? null
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ViewerNotice(
                  text: '${toAppException(error).message} 눌러서 다시 시도해 주세요.',
                  onTap: () => ref.invalidate(campusMapProvider),
                ),
              ),
            ),
    );
  }
}
