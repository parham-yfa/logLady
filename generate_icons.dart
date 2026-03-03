import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final configs = [
    (path: 'web/favicon.png',                size: 32,  maskable: false),
    (path: 'web/icons/Icon-192.png',         size: 192, maskable: false),
    (path: 'web/icons/Icon-512.png',         size: 512, maskable: false),
    (path: 'web/icons/Icon-maskable-192.png',size: 192, maskable: true),
    (path: 'web/icons/Icon-maskable-512.png',size: 512, maskable: true),
  ];

  for (final c in configs) {
    final image = _generateIcon(c.size, c.maskable);
    await File(c.path).writeAsBytes(img.encodePng(image));
    print('✓ ${c.path}');
  }
}

img.Image _generateIcon(int size, bool maskable) {
  // Maskable icons: keep content within 80% safe zone
  final double contentScale = maskable ? 0.8 : 1.0;
  final double pad = size * (1.0 - contentScale) / 2.0;

  // Map SVG 0-100 coordinate space to pixel space
  double p(double v) => pad + v / 100.0 * size * contentScale;
  int pi(double v) => p(v).round();

  final white = img.ColorRgba8(255, 255, 255, 255);
  final bgColor = img.ColorRgba8(0x2D, 0x34, 0x36, 255);

  final image = img.Image(width: size, height: size, numChannels: 4);

  // Background — rounded corners on regular icons, square on maskable
  img.fillRect(
    image,
    x1: 0, y1: 0, x2: size - 1, y2: size - 1,
    color: bgColor,
    radius: maskable ? 0 : (size * 0.22).round(),
  );

  final stroke = ((4.0 / 100.0) * size * contentScale).clamp(1.0, 50.0).round();

  // Head
  img.fillCircle(
    image,
    x: pi(50), y: pi(27),
    radius: ((9.0 / 100.0) * size * contentScale).round().clamp(1, size),
    color: white,
  );

  // Left arm:  M45 43 C38 39 30 33 32 22
  _bezier(image, p(45), p(43), p(38), p(39), p(30), p(33), p(32), p(22), white, stroke);

  // Right arm: M55 43 C62 39 70 33 68 22
  _bezier(image, p(55), p(43), p(62), p(39), p(70), p(33), p(68), p(22), white, stroke);

  // Torso
  img.drawLine(image, x1: pi(50), y1: pi(36), x2: pi(50), y2: pi(54), color: white, thickness: stroke);

  // Upper lotus arc: M36 68 C42 57 58 57 64 68
  _bezier(image, p(36), p(68), p(42), p(57), p(58), p(57), p(64), p(68), white, stroke);

  // Lower lotus left:  M28 68 C37 78 50 74 50 74
  _bezier(image, p(28), p(68), p(37), p(78), p(50), p(74), p(50), p(74), white, stroke);

  // Lower lotus right: C50 74 63 78 72 68
  _bezier(image, p(50), p(74), p(50), p(74), p(63), p(78), p(72), p(68), white, stroke);

  return image;
}

void _bezier(img.Image image,
    double x0, double y0, double x1, double y1,
    double x2, double y2, double x3, double y3,
    img.Color color, int thickness) {
  int? lx, ly;
  for (int i = 0; i <= 80; i++) {
    final t = i / 80.0;
    final mt = 1.0 - t;
    final x = (mt*mt*mt*x0 + 3*mt*mt*t*x1 + 3*mt*t*t*x2 + t*t*t*x3).round();
    final y = (mt*mt*mt*y0 + 3*mt*mt*t*y1 + 3*mt*t*t*y2 + t*t*t*y3).round();
    if (lx != null && ly != null) {
      img.drawLine(image, x1: lx, y1: ly, x2: x, y2: y, color: color, thickness: thickness);
    }
    lx = x;
    ly = y;
  }
}
