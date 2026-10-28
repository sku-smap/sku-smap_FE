import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../../campus/data/campus_models.dart';
import '../../data/navigation_assets.dart';
import '../../data/navigation_models.dart';
import '../../state/navigation_controller.dart';
import '../navigation_tokens.dart';
import 'link_arrow.dart';

class PanoView extends ConsumerStatefulWidget {
  const PanoView({
    super.key,
    required this.node,
    required this.links,
    required this.marks,
    required this.onNavigate,
    required this.onMark,
    this.onPhotoTap,
  });

  final PanoSpot node;
  final List<ViewLink> links;
  final List<PanoMark> marks;
  final ValueChanged<String> onNavigate;
  final ValueChanged<PanoMark> onMark;
  final ValueChanged<double>? onPhotoTap;

  @override
  ConsumerState<PanoView> createState() => _PanoViewState();
}

class _PanoViewState extends ConsumerState<PanoView> {
  var _loading = true;
  var _failed = false;
  var _attempt = 0;
  ImageStream? _stream;
  late final _listener = ImageStreamListener(
    (_, _) {},
    onError: (_, _) {
      if (mounted) setState(() => _failed = true);
    },
  );

  ImageProvider get _image =>
      ref.read(photoImageProvider)(NavigationAssets.pano(widget.node.id));

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  // Notice a missing or broken photo, which the viewer itself never reports
  void _watch() {
    _stream?.removeListener(_listener);
    _stream = _image.resolve(ImageConfiguration.empty)..addListener(_listener);
  }

  Future<void> _retry() async {
    await _image.evict();
    if (!mounted) return;
    setState(() {
      _failed = false;
      _loading = true;
      _attempt++;
    });
    _watch();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (_failed) return _PhotoError(onRetry: _retry);
    if (widget.node.flat) return _FlatPhoto(widget: widget, image: image);

    // Same destination twice gets one arrow
    final seen = <String>{};
    final links = [
      for (final l in widget.links)
        if (seen.add(l.to)) l,
    ];
    final primaryYaw = links.where((l) => l.primary).firstOrNull?.yaw ?? 0;

    return ColoredBox(
      color: NavColors.photoBg,
      child: Stack(
        children: [
          Positioned.fill(
            child: PanoramaViewer(
              key: ValueKey(_attempt),
              // Face the next path when the photo opens
              longitude: primaryYaw,
              latitude: -5,
              onTap: widget.onPhotoTap == null
                  ? null
                  : (longitude, _, _) => widget.onPhotoTap!(longitude),
              onImageLoad: () {
                if (mounted && _loading) setState(() => _loading = false);
              },
              hotspots: [
                for (final m in widget.marks)
                  Hotspot(
                    longitude: m.yaw,
                    latitude: m.pitch,
                    width: m.label ? 220 : 180,
                    height: m.label ? 80 : 170,
                    orgin: m.label
                        ? const Offset(0.5, 1)
                        : const Offset(0.5, 0.5),
                    widget: _MarkView(mark: m, onTap: () => widget.onMark(m)),
                  ),
                for (final l in links)
                  Hotspot(
                    longitude: l.yaw,
                    latitude: -17,
                    width: LinkArrow.width,
                    height: LinkArrow.height,
                    widget: Center(
                      child: LinkArrow(
                        link: l,
                        onTap: () => widget.onNavigate(l.to),
                      ),
                    ),
                  ),
              ],
              child: Image(image: image),
            ),
          ),
          if (_loading) const Center(child: _Loading()),
        ],
      ),
    );
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NavColors.photoBg,
      child: Center(
        child: Semantics(
          button: true,
          liveRegion: true,
          child: GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NavColors.loading,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('사진을 불러오지 못했어요 · 다시 시도', style: NavText.loading),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: NavColors.loading,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
              backgroundColor: Color(0x4DFFFFFF),
            ),
          ),
          const SizedBox(width: 10),
          Text('사진 불러오는 중', style: NavText.loading),
        ],
      ),
    );
  }
}

class _MarkView extends StatelessWidget {
  const _MarkView({required this.mark, required this.onTap});

  final PanoMark mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: mark.label ? _tag() : _blocked(),
    );
  }

  Widget _tag() => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: NavColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: NavShadows.glass,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mark.title, style: NavText.tagName),
            if (mark.desc.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: NavColors.blue,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'i',
                  style: NavText.mapLevel.copyWith(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
      Container(width: 2, height: 22, color: NavColors.surface),
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: NavColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: NavColors.surface, width: 2),
        ),
      ),
    ],
  );

  Widget _blocked() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: NavColors.markX,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xBFFFFFFF), width: 3),
        ),
        child: const CustomPaint(painter: _CrossPainter()),
      ),
      const SizedBox(height: 6),
      Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: NavColors.markLabel,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          mark.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: NavText.markLabel,
        ),
      ),
    ],
  );
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    const d = 46 * 0.7071;
    canvas
      ..drawLine(c.translate(-d, -d), c.translate(d, d), paint)
      ..drawLine(c.translate(d, -d), c.translate(-d, d), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => false;
}

// Plain photo spots: photo plus link chips instead of 360 arrows
class _FlatPhoto extends StatelessWidget {
  const _FlatPhoto({required this.widget, required this.image});

  final PanoView widget;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NavColors.photoBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Image(
              image: image,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              '이 지점은 일반 사진이에요 (360 재촬영 필요)',
              style: NavText.stepHint.copyWith(color: const Color(0xB3FFFFFF)),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final l in widget.links)
                GestureDetector(
                  onTap: () => widget.onNavigate(l.to),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: l.primary ? NavColors.blue : NavColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.primary ? '다음 → ${l.label}' : l.label,
                      style: NavText.rateChip.copyWith(
                        fontSize: 14,
                        color: l.primary ? NavColors.surface : NavColors.navy,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 230),
        ],
      ),
    );
  }
}
