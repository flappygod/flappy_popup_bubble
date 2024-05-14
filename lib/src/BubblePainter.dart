import 'package:flutter/material.dart';
import 'dart:math';

///bubble type
enum BubbleType {
  left,
  top,
  right,
  bottom,
}

///paint
class BubblePainter extends CustomPainter {
  ///left
  final BubbleType type;

  ///radius
  final BorderRadius radius;

  ///color
  final Color color;

  ///offset of bubble
  final double deltaOffset;

  ///delta height
  final double deltaHeight;

  ///delta length
  final double deltaLength;

  ///delta length
  final double deltaCorner;

  BubblePainter({
    this.radius = const BorderRadius.all(Radius.circular(5)),
    this.color = Colors.white,
    this.type = BubbleType.bottom,
    required this.deltaOffset,
    required this.deltaLength,
    required this.deltaHeight,
    required this.deltaCorner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.bevel
      ..style = PaintingStyle.fill
      ..color = color;

    ///draw rect
    canvas.drawRRect(
      _buildRRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      paint,
    );

    ///true offset
    double offsetTrue = deltaOffset - deltaLength / 2;

    ///draw delta
    switch (type) {
      case BubbleType.left:

        ///draw delta
        Path path = Path()..moveTo(0, offsetTrue);
        path.lineTo(0, offsetTrue + deltaLength);
        path.lineTo(0 - deltaHeight, offsetTrue + deltaLength / 2 + deltaCorner / 2);
        double radius = (deltaCorner / 2) / cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
        path.arcToPoint(
          Offset(0 - deltaHeight, offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(radius),
          clockwise: true,
        );
        path.lineTo(0, offsetTrue);
        canvas.drawPath(path, paint);
        break;

      case BubbleType.top:

        ///draw delta
        Path path = Path()..moveTo(offsetTrue, 0);
        path.lineTo(offsetTrue + deltaLength, 0);
        path.lineTo(offsetTrue + deltaLength / 2 + deltaCorner / 2, -deltaHeight);
        double radius = (deltaCorner / 2) / cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2, -deltaHeight),
          radius: Radius.circular(radius),
          clockwise: false,
        );
        path.lineTo(offsetTrue, 0);
        canvas.drawPath(path, paint);
        break;

      case BubbleType.right:

        ///draw delta
        Path path = Path()..moveTo(size.width, offsetTrue);
        path.lineTo(size.width, offsetTrue + deltaLength);
        path.lineTo(size.width + deltaHeight, offsetTrue + deltaLength / 2 + deltaCorner / 2);
        double radius = (deltaCorner / 2) / cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
        path.arcToPoint(
          Offset(size.width + deltaHeight, offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(radius),
          clockwise: false,
        );
        path.lineTo(size.width, offsetTrue);
        canvas.drawPath(path, paint);
        break;

      case BubbleType.bottom:

        ///draw delta
        Path path = Path()..moveTo(offsetTrue, size.height);
        path.lineTo(offsetTrue + deltaLength, size.height);
        path.lineTo(offsetTrue + deltaLength / 2 + deltaCorner / 2, size.height + deltaHeight);
        double radius = (deltaCorner / 2) / cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2, size.height + deltaHeight),
          radius: Radius.circular(radius),
          clockwise: true,
        );
        path.lineTo(offsetTrue, size.height);
        canvas.drawPath(path, paint);
        break;
    }
  }

  ///build RRect
  RRect _buildRRect(Rect rect) {
    return RRect.fromRectAndCorners(
      rect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.deltaCorner != deltaCorner ||
        oldDelegate.deltaOffset != deltaOffset ||
        oldDelegate.deltaHeight != deltaHeight ||
        oldDelegate.deltaLength != deltaLength ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
