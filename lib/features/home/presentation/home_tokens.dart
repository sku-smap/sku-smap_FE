import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

const homeFontFamily = 'Gothic A1';

abstract final class HomeColors {
  static const hero = AppColors.hero;
  static const heroTitle = AppColors.blueSoft;
  static const background = AppColors.grey100;
  static const surface = AppColors.surface;
  static const field = AppColors.grey100;
  static const track = AppColors.grey200;
  static const border = AppColors.grey200;
  static const disabled = AppColors.grey300;
  static const text = AppColors.grey900;
  static const muted = AppColors.grey700;
  static const placeholder = AppColors.grey500;
  static const blue = AppColors.blue;
  static const navy = AppColors.navy;
  static const blueSoft = AppColors.blueSoft;

  static const mapStage = Color(0xFFEEF0F3);
  static const closure = Color(0xFFFFF4E5);
  static const closureText = Color(0xFF7A4B00);
  static const pressed = Color(0x0F00156A);
  static const backdrop = Color(0x73000A32);
  static const caption = Color(0x73000000);
}

abstract final class HomeShadows {
  static const card = [
    BoxShadow(color: Color(0x1200146B), offset: Offset(0, 6), blurRadius: 10),
    BoxShadow(color: Color(0x0F00146B), offset: Offset(0, 1), blurRadius: 1),
  ];
  static const searchBar = [
    BoxShadow(color: Color(0x33000000), blurRadius: 0.5),
  ];
  static const segmentThumb = [
    BoxShadow(color: Color(0x2600146B), offset: Offset(0, 1), blurRadius: 1.5),
  ];
  static const pin = [
    BoxShadow(color: Color(0x4D00146B), offset: Offset(0, 2), blurRadius: 1.5),
  ];
  static const micCircle = [
    BoxShadow(color: Color(0x291A293D), offset: Offset(0, 5), blurRadius: 9.5),
  ];
}

abstract final class HomeLayout {
  static const screenH = 20.0;
  static const heroTop = 52.0;
  static const heroBottom = 31.0;
  static const heroRadius = 28.0;
  static const sectionGap = 17.0;
  static const mapCardGap = 15.0;

  static const cardRadius = 20.0;
  static const cardPadding = 20.0;
  static const searchHeight = 52.0;
  static const searchRadius = 14.0;

  static const fieldHeight = 50.0;
  static const fieldGap = 8.0;
  static const fieldRadius = 12.0;
  static const railWidth = 10.0;
  static const swapSize = 44.0;
  static const segmentHeight = 40.0;
  static const segmentInset = 3.0;
  static const segmentPadding = 12.0;
  static const goHeight = 48.0;
  static const toggleHeight = 54.0;
  static const toggleRadius = 14.0;

  static const chipHeight = 38.0;
  static const facChipHeight = 32.0;
  static const chipGap = 8.0;
  static const facChipGap = 6.0;

  static const mapAspect = 310 / 207.1;
  static const stageRadius = 14.0;
  static const pinHeight = 24.5;

  static const tabbarHeight = 60.0;
  static const tabbarMinInset = 34.0;
  static const tabbarRadius = 30.0;
  static const tabbarMargin = 2.0;
  static const notchWidth = 156.0;
  static const notchDip = 75.0;
  static const micCircle = 82.0;
  static const micRise = 30.0;
  static const tabIconOffset = 123.0;
  static const scrollBottom = 108.0;

  static const sheetRadius = 24.0;
  static const sheetMaxHeight = 0.86;
  static const photoHeight = 150.0;
}

abstract final class HomeText {
  static const _base = TextStyle(
    fontFamily: homeFontFamily,
    color: HomeColors.text,
  );

  static final heroTitle = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 35 / 26,
    letterSpacing: -2.2,
    color: HomeColors.heroTitle,
  );
  static final searchHint = _base.copyWith(
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -1.2111,
    color: HomeColors.placeholder,
  );
  static final fieldLabel = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
    letterSpacing: -1.6,
    color: HomeColors.muted,
  );
  static final fieldPlaceholder = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
    letterSpacing: -0.86,
    color: HomeColors.placeholder,
  );
  static final fieldValue = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
    letterSpacing: -1.9,
  );
  static final segment = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 15.6 / 13,
    letterSpacing: -1.3,
  );
  static final goButton = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 19.2 / 16,
    letterSpacing: -2.8667,
    color: HomeColors.surface,
  );
  static final toggleIcon = _base.copyWith(fontSize: 18, height: 21.6 / 18);
  static final toggleTitle = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 16.8 / 14,
    letterSpacing: -1.49,
  );
  static final toggleSub = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    letterSpacing: -0.9063,
    color: HomeColors.muted,
  );
  static final quickChip = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 16.8 / 14,
    letterSpacing: -2,
    color: HomeColors.navy,
  );
  static final closureTitle = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 18 / 15,
    letterSpacing: -0.7643,
    color: HomeColors.closureText,
  );
  static final closureItem = _base.copyWith(
    fontSize: 13,
    height: 20.8 / 13,
    letterSpacing: -0.7742,
    color: HomeColors.closureText,
  );
  static final closureSmall = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    letterSpacing: -0.9882,
    color: HomeColors.closureText,
  );
  static final cardTitle = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 25.5 / 17,
    letterSpacing: -1.9333,
  );
  static final cardSub = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 15.6 / 13,
    letterSpacing: -1.4444,
    color: HomeColors.muted,
  );
  static final facChip = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 15.6 / 13,
    letterSpacing: -2.2,
    color: HomeColors.navy,
  );
  static final pin = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 16.5 / 11,
    letterSpacing: -1.8667,
    color: HomeColors.surface,
  );
  static final mapNote = _base.copyWith(
    fontSize: 13,
    height: 19.5 / 13,
    letterSpacing: -0.8462,
    color: HomeColors.muted,
  );
  static final tabLabel = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14.4 / 12,
    letterSpacing: -1.6,
    color: HomeColors.placeholder,
  );
  static final micLabel = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 20.4 / 17,
    letterSpacing: -1.6714,
    color: HomeColors.blue,
  );
  static final sheetTitle = _base.copyWith(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    height: 25.2 / 21,
    letterSpacing: -2.9,
    color: HomeColors.navy,
  );
  static final sheetDepts = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 18.9 / 13,
    letterSpacing: -1.75,
    color: HomeColors.blue,
  );
  static final sheetBody = _base.copyWith(
    fontSize: 15,
    height: 22.5 / 15,
    letterSpacing: -1.0194,
    color: HomeColors.muted,
  );
  static final sheetFloor = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 16.8 / 14,
    letterSpacing: 0.15,
    color: HomeColors.navy,
  );
  static final sheetChip = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 16.8 / 14,
    letterSpacing: -1.2,
    color: HomeColors.blue,
  );
  static final photoCaption = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
    letterSpacing: -1.0286,
    color: HomeColors.surface,
  );
  static final sheetAction = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 18 / 15,
    letterSpacing: -2.4286,
    color: HomeColors.navy,
  );

  // Per-label tracking from Figma where fixed labels differ from the base style
  static const tracking = {
    '본관': -2.3,
    '출발지 선택 (NFC 태그 시 자동)': -0.86,
    '도착지 선택': -1.2167,
    '엘리베이터 우선': -1.4,
    '지상': -1.75,
    '지하': -1.75,
    '매점·편의점': -1.8167,
    'ATM·은행': -1.0167,
    '우체국': -1.8667,
    '복사·서점': -1.94,
    '건물을 눌러보세요': -1.4444,
    '편의시설 핀을 눌러보세요': -1.4444,
    '거리뷰': -2.7333,
    '여기서 출발': -2.3167,
    '여기로 길찾기': -2.4286,
    '지금 캠퍼스에 비가 와요': -1.4846,
    '지붕 있는 실내·지하 길로 먼저 안내해요': -0.9091,
  };

  static TextStyle tracked(TextStyle style, String label) {
    final value = tracking[label];
    return value == null ? style : style.copyWith(letterSpacing: value);
  }
}
