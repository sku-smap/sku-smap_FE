import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../campus/data/campus_models.dart';
import '../../../campus/state/trip_controller.dart';
import '../../data/home_assets.dart';
import '../home_tokens.dart';
import 'home_segmented.dart';
import 'pressable.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.trip,
    required this.weather,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
    required this.onMode,
    required this.onGo,
    required this.onIndoor,
  });

  final TripState trip;
  final CampusWeather weather;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;
  final ValueChanged<RouteMode> onMode;
  final VoidCallback onGo;
  final VoidCallback onIndoor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeLayout.cardPadding),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(HomeLayout.cardRadius),
        boxShadow: HomeShadows.card,
      ),
      child: Column(
        children: [
          SizedBox(
            height: HomeLayout.fieldHeight * 2 + HomeLayout.fieldGap,
            child: Row(
              children: [
                const _Rail(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      _RouteField(
                        label: '출발',
                        value: trip.from?.name,
                        placeholder: '출발지 선택 (NFC 태그 시 자동)',
                        onTap: onPickFrom,
                      ),
                      const SizedBox(height: HomeLayout.fieldGap),
                      _RouteField(
                        label: '도착',
                        value: trip.to?.name,
                        placeholder: '도착지 선택',
                        onTap: onPickTo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SwapButton(onTap: onSwap),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: HomeLayout.goHeight,
            child: Row(
              children: [
                // Indoor-first is its own route option, so the modes hide
                if (!trip.indoor) ...[
                  HomeSegmented<RouteMode>(
                    options: const [
                      (RouteMode.outdoor, '야외경로'),
                      (RouteMode.comfortable, '편한길'),
                      (RouteMode.shortest, '최단거리'),
                    ],
                    selected: trip.mode,
                    onChanged: onMode,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: _GoButton(onTap: trip.canRoute ? onGo : null)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _IndoorToggle(on: trip.indoor, weather: weather, onTap: onIndoor),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HomeLayout.railWidth,
      child: Stack(
        children: [
          Positioned(
            top: 18,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: HomeColors.blue, width: 3),
              ),
            ),
          ),
          Positioned(
            top: 32,
            left: 4,
            child: Container(
              width: 2,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HomeColors.border,
                    HomeColors.border,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: [0, 1 / 3, 2 / 3, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: HomeColors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteField extends StatelessWidget {
  const _RouteField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value;
    return Pressable(
      onTap: onTap,
      label: '$label ${text ?? placeholder}',
      builder: (context, pressed) => Container(
        height: HomeLayout.fieldHeight,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        decoration: BoxDecoration(
          color: HomeColors.field,
          borderRadius: BorderRadius.circular(HomeLayout.fieldRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: HomeText.fieldLabel),
            const SizedBox(height: 2),
            Text(
              text ?? placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text != null
                  ? HomeText.fieldValue
                  : HomeText.tracked(HomeText.fieldPlaceholder, placeholder),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: '출발지·도착지 바꾸기',
      builder: (context, pressed) => Container(
        width: HomeLayout.swapSize,
        height: HomeLayout.swapSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? HomeColors.pressed : Colors.transparent,
          borderRadius: BorderRadius.circular(HomeLayout.fieldRadius),
        ),
        child: SvgPicture.asset(HomeAssets.swap, width: 24, height: 24),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: '길찾기',
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: HomeLayout.goHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? HomeColors.disabled : HomeColors.blue,
          borderRadius: BorderRadius.circular(HomeLayout.fieldRadius),
        ),
        child: Text('길찾기', maxLines: 1, style: HomeText.goButton),
      ),
    );
  }
}

class _IndoorToggle extends StatelessWidget {
  const _IndoorToggle({
    required this.on,
    required this.weather,
    required this.onTap,
  });

  final bool on;
  final CampusWeather weather;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wet = weather.wetKind;
    final temperature = weather.temperature;
    final title = wet == null
        ? '실내·지하 길 우선'
        : '지금 캠퍼스에 ${wet.subject} 와요'
              '${temperature == null ? '' : ' · ${temperature.round()}°'}';
    final sub = on
        ? '지붕 있는 실내·지하 길로 먼저 안내해요'
        : wet != null
        ? '켜면 비를 덜 맞는 길로 안내해요'
        : '비 오는 날에 사용해보세요!';

    return Semantics(
      toggled: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: HomeLayout.toggleHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: wet != null ? HomeColors.blueSoft : HomeColors.field,
            borderRadius: BorderRadius.circular(HomeLayout.toggleRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: HomeColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(wet?.icon ?? '☂️', style: HomeText.toggleIcon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeText.tracked(
                        HomeText.toggleTitle,
                        title,
                      ).copyWith(color: wet != null ? HomeColors.navy : null),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeText.tracked(HomeText.toggleSub, sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Switch(on: on),
            ],
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? HomeColors.blue : HomeColors.disabled,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: HomeColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
