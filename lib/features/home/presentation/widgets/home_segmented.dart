import 'package:flutter/material.dart';

import '../home_tokens.dart';

class HomeSegmented<T> extends StatelessWidget {
  const HomeSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: HomeLayout.segmentHeight,
      padding: const EdgeInsets.all(HomeLayout.segmentInset),
      decoration: BoxDecoration(
        color: HomeColors.track,
        borderRadius: BorderRadius.circular(HomeLayout.fieldRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            _Segment(
              label: label,
              selected: value == selected,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: HomeLayout.segmentPadding,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? HomeColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(HomeLayout.fieldRadius),
            boxShadow: selected ? HomeShadows.segmentThumb : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: HomeText.tracked(
              HomeText.segment,
              label,
            ).copyWith(color: selected ? HomeColors.text : HomeColors.muted),
          ),
        ),
      ),
    );
  }
}
