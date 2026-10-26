import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/home_assets.dart';
import '../home_tokens.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.onMap,
    required this.onVoice,
    required this.onReport,
  });

  final VoidCallback onMap;
  final VoidCallback onVoice;
  final VoidCallback onReport;

  static double heightOf(BuildContext context) =>
      HomeLayout.tabbarHeight +
      math.max(MediaQuery.paddingOf(context).bottom, HomeLayout.tabbarMinInset);

  @override
  Widget build(BuildContext context) {
    final barHeight = heightOf(context);
    return LayoutBuilder(
      builder: (context, size) {
        final center = size.maxWidth / 2;
        final leftWidth =
            center - HomeLayout.notchDip - HomeLayout.tabbarMargin;
        return SizedBox(
          height: barHeight + HomeLayout.micRise,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: HomeLayout.tabbarMargin,
                right: HomeLayout.tabbarMargin,
                bottom: 0,
                height: barHeight,
                child: Row(
                  children: [
                    Container(
                      width: leftWidth,
                      decoration: const BoxDecoration(
                        color: HomeColors.surface,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(HomeLayout.tabbarRadius),
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      HomeAssets.tabbarNotch,
                      width: HomeLayout.notchWidth,
                      height: barHeight,
                      fit: BoxFit.fill,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: HomeColors.surface,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(HomeLayout.tabbarRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _SideTab(
                centerX: center - HomeLayout.tabIconOffset,
                icon: HomeAssets.tabMap,
                label: '지도',
                onTap: onMap,
              ),
              _SideTab(
                centerX: center + HomeLayout.tabIconOffset - 1,
                icon: HomeAssets.tabReport,
                label: '제보',
                onTap: onReport,
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _MicButton(onTap: onVoice),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SideTab extends StatelessWidget {
  const _SideTab({
    required this.centerX,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _width = 64.0;

  final double centerX;
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centerX - _width / 2,
      top: HomeLayout.micRise + 21,
      width: _width,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              SvgPicture.asset(icon, width: 24, height: 24),
              const SizedBox(height: 3.8),
              Text(label, style: HomeText.tabLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '말로 길 묻기',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: HomeLayout.micCircle,
              height: HomeLayout.micCircle,
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 5,
                    width: 62,
                    height: 62,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: HomeShadows.micCircle,
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    HomeAssets.tabMicCircle,
                    width: HomeLayout.micCircle,
                    height: HomeLayout.micCircle,
                  ),
                  Positioned(
                    left: 32.4,
                    top: 24.6,
                    child: SvgPicture.asset(
                      HomeAssets.tabMic,
                      width: 17,
                      height: 23,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.8),
            Text('말로 길 묻기', maxLines: 1, style: HomeText.micLabel),
          ],
        ),
      ),
    );
  }

  final VoidCallback onTap;
}
