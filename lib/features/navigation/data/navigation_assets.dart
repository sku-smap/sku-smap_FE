abstract final class NavigationAssets {
  static const _icons = 'assets/icons/navigation';
  static const mapOn = '$_icons/map_on.svg';
  static const mapOff = '$_icons/map_off.svg';
  static const soundOn = '$_icons/sound_on.svg';
  static const soundOff = '$_icons/sound_off.svg';
  static const list = '$_icons/list.svg';
  static const share = '$_icons/share.svg';
  static const flag = '$_icons/flag.svg';
  static const close = '$_icons/close.svg';

  static const _photos =
      'https://lbtejkdwevtxpoyplvil.supabase.co/storage/v1/object/public/smap';
  static String pano(String node) => '$_photos/pano/$node.jpg';
  static String thumb(String node) => '$_photos/thumb/$node.jpg';

  static const shareBase = 'https://smap-tawny.vercel.app/';
}
