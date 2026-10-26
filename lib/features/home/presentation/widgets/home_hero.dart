import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/home_assets.dart';
import '../home_tokens.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.onSearch, required this.routeCard});

  final VoidCallback onSearch;
  final Widget routeCard;

  @override
  Widget build(BuildContext context) {
    final top = math.max(
      HomeLayout.heroTop,
      MediaQuery.paddingOf(context).top + 5,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HomeColors.hero,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(HomeLayout.heroRadius),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          HomeLayout.screenH,
          top,
          HomeLayout.screenH,
          HomeLayout.heroBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('어디로 갈까요?', style: HomeText.heroTitle),
            const SizedBox(height: 14),
            _SearchBar(onTap: onSearch),
            const SizedBox(height: 16),
            routeCard,
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: HomeLayout.searchHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(HomeLayout.searchRadius),
            boxShadow: HomeShadows.searchBar,
          ),
          child: Row(
            children: [
              SvgPicture.asset(HomeAssets.search, width: 24, height: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '건물, 부서, 교수님 연구실 검색',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeText.searchHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
