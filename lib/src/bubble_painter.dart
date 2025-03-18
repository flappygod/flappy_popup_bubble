import 'package:flutter/material.dart';
import 'dart:math';

/// Bubble type
enum BubbleType {
  left,
  top,
  right,
  bottom,
}

/// Custom painter for bubble
class BubblePainter extends CustomPainter {
  /// Bubble position type
  final BubbleType type;

  /// Border radius of the bubble
  final BorderRadius radius;

  /// Bubble color
  final Color color;

  /// Offset of the bubble's arrow
  final double deltaOffset;

  /// Height of the bubble's arrow
  final double deltaHeight;

  /// Length of the bubble's arrow
  final double deltaLength;

  /// Corner radius of the bubble's arrow
  final double deltaCorner;

  /// Paint object for drawing
  final Paint _paint;

  /// Cached arrow radius
  double? _arrowRadius;

  BubblePainter({
    this.radius = const BorderRadius.all(Radius.circular(5)),
    this.color = Colors.white,
    this.type = BubbleType.bottom,
    required this.deltaOffset,
    required this.deltaLength,
    required this.deltaHeight,
    required this.deltaCorner,
  }) : _paint = Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = color;

  /// Get the arrow radius, calculate only when necessary
  double get arrowRadius {
    _arrowRadius ??= (deltaCorner / 2) / cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
    return _arrowRadius!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the main bubble rectangle
    canvas.drawRRect(
      _buildRRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      _paint,
    );

    // Calculate the true offset for the arrow
    double offsetTrue = deltaOffset - deltaLength / 2;

    offsetTrue = max(0, offsetTrue);
    switch (type) {
      case BubbleType.left:
      case BubbleType.right:
        offsetTrue = min(size.height - deltaLength, offsetTrue);
        break;
      case BubbleType.bottom:
      case BubbleType.top:
        offsetTrue = min(size.width - deltaLength, offsetTrue);
        break;
    }

    // Draw the arrow based on the bubble type
    final Path arrowPath = _buildArrowPath(size, offsetTrue);
    canvas.drawPath(arrowPath, _paint);
  }

  /// Build the rounded rectangle for the bubble
  RRect _buildRRect(Rect rect) {
    return RRect.fromRectAndCorners(
      rect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
  }

  /// Build the arrow path based on the bubble type
  Path _buildArrowPath(Size size, double offsetTrue) {
    final Path path = Path();

    switch (type) {
      case BubbleType.left:
        path.moveTo(0, offsetTrue + deltaLength);
        path.lineTo(-deltaHeight, offsetTrue + deltaLength / 2 + deltaCorner / 2);
        path.arcToPoint(
          Offset(-deltaHeight, offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        path.lineTo(0, offsetTrue);

        //then
        path.arcToPoint(
          Offset(radius.topLeft.x, 0),
          radius: Radius.elliptical(radius.topLeft.x, offsetTrue),
          clockwise: true,
        );
        path.lineTo(radius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, offsetTrue + deltaLength),
          radius: Radius.elliptical(radius.bottomLeft.x, size.height - offsetTrue - deltaLength),
          clockwise: true,
        );
        path.close();
        break;

      case BubbleType.top:
        path.moveTo(offsetTrue + deltaLength, 0);
        path.lineTo(offsetTrue + deltaLength / 2 + deltaCorner / 2, -deltaHeight);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2, -deltaHeight),
          radius: Radius.circular(arrowRadius),
          clockwise: false,
        );
        path.lineTo(offsetTrue, 0);

        //then
        path.arcToPoint(
          Offset(0, radius.topLeft.y),
          radius: Radius.elliptical(offsetTrue, radius.topLeft.y),
          clockwise: false,
        );
        path.lineTo(size.width, radius.topRight.y);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength, 0),
          radius: Radius.elliptical(size.width - offsetTrue - deltaLength, radius.topRight.y),
          clockwise: false,
        );
        path.close();
        break;

      case BubbleType.right:
        path.moveTo(size.width, offsetTrue + deltaLength);
        path.lineTo(size.width + deltaHeight, offsetTrue + deltaLength / 2 + deltaCorner / 2);
        path.arcToPoint(
          Offset(size.width + deltaHeight, offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: false,
        );
        path.lineTo(size.width, offsetTrue);

        //then
        path.arcToPoint(
          Offset(size.width - radius.topRight.x, 0),
          radius: Radius.elliptical(radius.topRight.x, offsetTrue),
          clockwise: false,
        );
        path.lineTo(size.width - radius.bottomRight.x, size.height);
        path.arcToPoint(
          Offset(size.width, offsetTrue + deltaLength),
          radius: Radius.elliptical(radius.bottomRight.x, size.height - offsetTrue - deltaLength),
          clockwise: false,
        );

        path.close();
        break;

      case BubbleType.bottom:
        path.moveTo(offsetTrue + deltaLength, size.height);
        path.lineTo(offsetTrue + deltaLength / 2 + deltaCorner / 2, size.height + deltaHeight);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2, size.height + deltaHeight),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        path.lineTo(offsetTrue, size.height);

        //then
        path.arcToPoint(
          Offset(0, size.height - radius.bottomLeft.y),
          radius: Radius.elliptical(offsetTrue, radius.bottomLeft.y),
          clockwise: true,
        );
        path.lineTo(size.width, size.height - radius.bottomRight.y);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength, size.height),
          radius: Radius.elliptical(size.width - offsetTrue - deltaLength, radius.bottomRight.y),
          clockwise: true,
        );
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    final bool needsRepaint = oldDelegate.type != type ||
        oldDelegate.deltaCorner != deltaCorner ||
        oldDelegate.deltaOffset != deltaOffset ||
        oldDelegate.deltaHeight != deltaHeight ||
        oldDelegate.deltaLength != deltaLength ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;

    // If parameters affecting arrowRadius change, reset the cached value
    if (needsRepaint &&
        (oldDelegate.deltaCorner != deltaCorner ||
            oldDelegate.deltaLength != deltaLength ||
            oldDelegate.deltaHeight != deltaHeight)) {
      _arrowRadius = null; // Reset cached value
    }

    return needsRepaint;
  }
}
