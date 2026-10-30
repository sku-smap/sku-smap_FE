import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

typedef PhotoFetch = Future<Uint8List> Function(String url);

// Compressed photo files kept in memory by their address without the
// signature, so a re-signed URL still hits; decoding waits until shown
class PhotoCache {
  PhotoCache(this._fetch, {this.maxBytes = 80 * 1024 * 1024});

  final PhotoFetch _fetch;
  final int maxBytes;

  // Insertion order doubles as least recently used first
  final _bytes = <String, Uint8List>{};
  final _loading = <String, Future<Uint8List>>{};
  var _size = 0;
  var _run = 0;

  int get size => _size;

  // Scheme, host and path; the query holds the expiring signature
  static String keyOf(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return url;
    return '${uri.scheme}://${uri.authority}${uri.path}';
  }

  bool has(String url) => _bytes.containsKey(keyOf(url));

  // A photo on screen may push out the oldest ones to fit
  Future<Uint8List> fetch(String url) => _load(url, evict: true);

  // One download per file even when the screen and a prefetch both ask
  Future<Uint8List> _load(String url, {required bool evict}) async {
    final key = keyOf(url);
    final hit = _bytes.remove(key);
    if (hit != null) {
      _bytes[key] = hit;
      return hit;
    }
    final bytes = await (_loading[key] ??= _fetch(url).whenComplete(() {
      _loading.remove(key);
    }));
    if (!_bytes.containsKey(key)) _store(key, bytes, evict: evict);
    return bytes;
  }

  void _store(String key, Uint8List bytes, {required bool evict}) {
    if (bytes.length > maxBytes) return;
    if (!evict && _size + bytes.length > maxBytes) return;
    _bytes[key] = bytes;
    _size += bytes.length;
    while (_size > maxBytes) {
      _size -= _bytes.remove(_bytes.keys.first)!.length;
    }
  }

  // Fetch the rest of a route one photo at a time without pushing out photos
  // still ahead; a newer call replaces it and a failure loads on demand later
  Future<void> prefetch(List<String> urls) async {
    final run = ++_run;
    for (final url in urls) {
      if (run != _run) return;
      try {
        await _load(url, evict: false);
      } on Object {
        continue;
      }
      if (!has(url)) return;
    }
  }

  void cancel() => _run++;

  void clear() {
    _run++;
    _bytes.clear();
    _size = 0;
  }
}

// A photo decoded from the cache; equal across re-signed URLs of one file
class CachedPhoto extends ImageProvider<CachedPhoto> {
  const CachedPhoto(this.url, this.cache);

  final String url;
  final PhotoCache cache;

  String get _key => PhotoCache.keyOf(url);

  @override
  Future<CachedPhoto> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedPhoto key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: _key,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async =>
      decode(await ui.ImmutableBuffer.fromUint8List(await cache.fetch(url)));

  @override
  bool operator ==(Object other) => other is CachedPhoto && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}
