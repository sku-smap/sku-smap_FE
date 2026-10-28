import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../../search/data/search_assets.dart';
import '../../state/report_providers.dart';
import '../report_routes.dart';
import '../report_tokens.dart';
import '../widgets/mine_card.dart';

// Reports sent from this device and how far each one got
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myReportsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final data = mine.value;

    return Scaffold(
      backgroundColor: ReportColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => ReportRoutes.close(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 32 + bottom),
                children: [
                  if (data == null)
                    const _Message('불러오는 중…')
                  else ...[
                    if (!data.online)
                      const _Message('서버 연결 전이라 이 기기에 저장된 제보만 보여요.'),
                    if (data.rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 28,
                        ),
                        child: Text(
                          '아직 보낸 제보가 없어요.\n길이 헷갈리거나 못 가는 곳이 있으면 알려주세요!',
                          textAlign: TextAlign.center,
                          style: ReportText.empty,
                        ),
                      ),
                    for (final (i, r) in data.rows.indexed)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          i == 0 ? 12 : ReportLayout.cardGap,
                          16,
                          0,
                        ),
                        child: MineCard(report: r),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ReportLayout.headerHeight + 1,
      padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      decoration: const BoxDecoration(
        color: ReportColors.surface,
        border: Border(bottom: BorderSide(color: ReportColors.headerLine)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            label: '닫기',
            builder: (context, pressed) => SizedBox.square(
              dimension: ReportLayout.iconButton,
              child: Center(
                child: SvgPicture.asset(
                  SearchAssets.back,
                  width: ReportLayout.backIcon,
                  height: ReportLayout.backIcon,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text('내 제보 현황', style: ReportText.headerTitle),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: ReportText.message),
    );
  }
}
