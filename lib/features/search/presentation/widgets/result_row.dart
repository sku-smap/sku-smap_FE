import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/presentation/widgets/pressable.dart';
import '../../data/search_assets.dart';
import '../search_tokens.dart';

enum ResultIcon { pin, spot }

class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.highlighted = false,
  });

  final ResultIcon icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: title,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: pressed || highlighted
              ? SearchColors.pressed
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SearchLayout.rowRadius),
        ),
        child: Row(
          children: [
            _Icon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SearchText.rowTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SearchText.rowSub,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon});

  final ResultIcon icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SearchLayout.resultIcon,
      height: SearchLayout.resultIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SearchColors.blueSoft,
        borderRadius: BorderRadius.circular(SearchLayout.resultIconRadius),
      ),
      child: SvgPicture.asset(
        icon == ResultIcon.pin ? SearchAssets.pin : SearchAssets.here,
        width: 22,
        height: 22,
        colorFilter: icon == ResultIcon.spot
            ? const ColorFilter.mode(SearchColors.blue, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
