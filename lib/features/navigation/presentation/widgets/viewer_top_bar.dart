import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../search/data/search_assets.dart';
import '../../../search/data/search_models.dart';
import '../../data/navigation_assets.dart';
import '../../data/route_graph.dart';
import '../navigation_tokens.dart';
import 'glass_box.dart';

class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    super.key,
    required this.here,
    required this.showMap,
    required this.onBack,
    required this.onToggleMap,
  });

  final PanoSpot here;
  final bool showMap;
  final VoidCallback onBack;
  final VoidCallback onToggleMap;

  @override
  Widget build(BuildContext context) {
    final place = placeLabel(here);
    return Row(
      children: [
        _GlassButton(icon: SearchAssets.back, label: '홈으로', onTap: onBack),
        const SizedBox(width: 8),
        Expanded(
          child: GlassBox(
            radius: NavLayout.whereRadius,
            padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.isEmpty ? '야외' : place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NavText.wherePlace,
                    ),
                    Text(
                      here.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NavText.whereTitle,
                    ),
                  ],
                ),
                if (here.estimated)
                  Positioned(
                    top: 0,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: NavColors.estimatedBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('위치 추정', style: NavText.estimated),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _GlassButton(
          icon: showMap ? NavigationAssets.mapOn : NavigationAssets.mapOff,
          label: '미니맵',
          selected: showMap,
          onTap: onToggleMap,
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final on = selected;
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassBox(
          radius: NavLayout.topRadius,
          color: on == null
              ? NavColors.glass
              : on
              ? NavColors.navy
              : NavColors.glassOff,
          child: SizedBox.square(
            dimension: NavLayout.topButton,
            child: Center(child: SvgPicture.asset(icon, width: 22, height: 22)),
          ),
        ),
      ),
    );
  }
}
