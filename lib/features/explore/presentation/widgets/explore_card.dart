import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../../navigation/data/navigation_assets.dart';
import '../../../navigation/presentation/navigation_tokens.dart';
import '../explore_tokens.dart';

class ExploreCard extends StatelessWidget {
  const ExploreCard({
    super.key,
    required this.title,
    required this.onStart,
    required this.onReport,
  });

  final String title;
  final VoidCallback onStart;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ExploreLayout.cardPadding,
      decoration: BoxDecoration(
        color: NavColors.surface,
        borderRadius: BorderRadius.circular(NavLayout.cardRadius),
        boxShadow: NavShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('거리뷰 둘러보기 · 사진 속 화살표로 이동', style: ExploreText.sub),
                const SizedBox(height: 2),
                Text(title, style: ExploreText.title),
              ],
            ),
          ),
          const SizedBox(width: ExploreLayout.textGap),
          Pressable(
            onTap: onStart,
            builder: (context, pressed) => Container(
              height: NavLayout.buttonHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: ExploreLayout.buttonPadding,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pressed ? NavColors.pressed : NavColors.blue,
                borderRadius: BorderRadius.circular(NavLayout.buttonRadius),
              ),
              child: Text('여기서 출발', style: ExploreText.button),
            ),
          ),
          const SizedBox(width: ExploreLayout.buttonGap),
          Semantics(
            container: true,
            child: Pressable(
              onTap: onReport,
              label: '제보하기',
              builder: (context, pressed) => Container(
                width: NavLayout.buttonHeight,
                height: NavLayout.buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pressed ? NavColors.field : null,
                  border: Border.all(color: NavColors.line),
                  borderRadius: BorderRadius.circular(NavLayout.buttonRadius),
                ),
                child: SvgPicture.asset(
                  NavigationAssets.flag,
                  width: ExploreLayout.flagIcon,
                  height: ExploreLayout.flagIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
