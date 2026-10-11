/// Map pins and styles for places (DS17): a round badge in the place color with a white Phosphor
/// icon, white ring and soft shadow; a count bubble; a green "active now" dot. Rendered to bitmaps
/// for Google Maps markers and cached.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../ui/icons.dart';
import '../../ui/tokens.dart';

class PinStyle {
  const PinStyle({required this.color, required this.icon, this.count = 0, this.live = false, this.faded = false, this.big = false});
  final Color color;
  final PlaceIcon icon;
  final int count;
  final bool live;
  final bool faded;
  final bool big;

  @override
  bool operator ==(Object other) =>
      other is PinStyle &&
      other.color == color &&
      other.icon == icon &&
      other.count == count &&
      other.live == live &&
      other.faded == faded &&
      other.big == big;

  @override
  int get hashCode => Object.hash(color, icon, count, live, faded, big);
}

final _cache = <(PinStyle, double), BitmapDescriptor>{};

/// A marker bitmap for [style] at [dpr] (pins are 36 dp, 46 dp when [PinStyle.big]).
Future<BitmapDescriptor> placePinBitmap(PinStyle style, double dpr, Color success) async {
  final key = (style, dpr);
  final hit = _cache[key];
  if (hit != null) return hit;

  final d = style.big ? 46.0 : 36.0;
  const pad = 10.0; // room for the count bubble, dot and shadow
  final size = d + pad * 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  final center = Offset(size / 2, size / 2);
  final alpha = style.faded ? 0.5 : 1.0;

  canvas.drawCircle(
    center.translate(0, 2),
    d / 2,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.25 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.drawCircle(center, d / 2, Paint()..color = Colors.white.withValues(alpha: alpha));
  canvas.drawCircle(center, d / 2 - 2.5, Paint()..color = style.color.withValues(alpha: alpha));

  final glyph = placeIcon(style.icon, solid: true);
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(glyph.codePoint),
      style: TextStyle(fontFamily: glyph.fontFamily, fontSize: d * 0.5, color: Colors.white.withValues(alpha: alpha)),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  if (style.count > 1) {
    final c = center + Offset(d / 2 - 2, -d / 2 + 2);
    canvas.drawCircle(c, 9.5, Paint()..color = Colors.white);
    final t = TextPainter(
      text: TextSpan(
        text: '${style.count}',
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: style.color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(canvas, c - Offset(t.width / 2, t.height / 2));
  }
  if (style.live) {
    final c = center + Offset(d / 2 - 4, d / 2 - 4);
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
    canvas.drawCircle(c, 5, Paint()..color = success);
  }

  final image = await recorder.endRecording().toImage((size * dpr).round(), (size * dpr).round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final bitmap = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  return _cache[key] = bitmap;
}

/// DS17: a muted map so the colored pins carry the color — pale land, white roads, soft water, no POIs.
const mapStyleLight = '''
[
  {"elementType":"geometry","stylers":[{"color":"#eef0f3"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a9099"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f6f8"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#dcefd8"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#d9dde3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#d0d4da"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cfe3f6"}]}
]
''';

const mapStyleDark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#17181b"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6e7177"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#17181b"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#14261a"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2e3036"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a3d44"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d2236"}]}
]
''';

String mapStyleFor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? mapStyleDark : mapStyleLight;

/// DS17 radius circle: place color at 12% fill, 1.5 dp edge at 60% (faded when paused).
Circle placeCircle(Place p, Color color, {bool faded = false}) => Circle(
  circleId: CircleId(p.id),
  center: LatLng(p.latitude, p.longitude),
  radius: p.radiusMeters.toDouble(),
  fillColor: color.withValues(alpha: faded ? 0.06 : 0.13),
  strokeColor: color.withValues(alpha: faded ? 0.3 : 0.6),
  strokeWidth: 2,
);

/// Space for the map's own buttons and logo inside our chrome.
const mapLogoPadding = EdgeInsets.only(bottom: Space.s);
