import 'campus_models.dart';

abstract final class HomeAssets {
  static const _icons = 'assets/icons/home';
  static const search = '$_icons/search.svg';
  static const swap = '$_icons/swap.svg';
  static const eye = '$_icons/eye.svg';
  static const buildingNavy = '$_icons/building_navy.svg';
  static const buildingWhite = '$_icons/building_white.svg';

  static const tabMap = '$_icons/tab_map.svg';
  static const tabReport = '$_icons/tab_report.svg';
  static const tabMic = '$_icons/tab_mic.svg';
  static const tabMicCircle = '$_icons/tab_mic_circle.svg';
  static const tabbarNotch = '$_icons/tabbar_notch.svg';

  static const _images = 'assets/images/home';
  static const mapGround = '$_images/map_ground.svg';
  static const mapUnderground = '$_images/map_underground.svg';
  static const photoBonkwan = '$_images/building_bonkwan.jpg';
  static const photoYudam = '$_images/building_yudam.jpg';

  static String facilityNavy(FacilityCategory c) =>
      '$_icons/${c.name}_navy.svg';
  static String facilityWhite(FacilityCategory c) =>
      '$_icons/${c.name}_white.svg';
}
