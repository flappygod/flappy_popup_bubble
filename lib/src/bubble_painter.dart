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
    _arrowRadius ??= (deltaCorner / 2) /
        cos(atan((deltaLength - deltaCorner) / 2 / deltaHeight));
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
    final double offsetTrue = deltaOffset - deltaLength / 2;

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
        path.moveTo(0, offsetTrue);
        path.lineTo(0, offsetTrue + deltaLength);
        path.lineTo(
            -deltaHeight, offsetTrue + deltaLength / 2 + deltaCorner / 2);
        path.arcToPoint(
          Offset(-deltaHeight, offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        path.close();
        break;

      case BubbleType.top:
        path.moveTo(offsetTrue, 0);
        path.lineTo(offsetTrue + deltaLength, 0);
        path.lineTo(
            offsetTrue + deltaLength / 2 + deltaCorner / 2, -deltaHeight);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2, -deltaHeight),
          radius: Radius.circular(arrowRadius),
          clockwise: false,
        );
        path.close();
        break;

      case BubbleType.right:
        path.moveTo(size.width, offsetTrue);
        path.lineTo(size.width, offsetTrue + deltaLength);
        path.lineTo(size.width + deltaHeight,
            offsetTrue + deltaLength / 2 + deltaCorner / 2);
        path.arcToPoint(
          Offset(size.width + deltaHeight,
              offsetTrue + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: false,
        );
        path.close();
        break;

      case BubbleType.bottom:
        path.moveTo(offsetTrue, size.height);
        path.lineTo(offsetTrue + deltaLength, size.height);
        path.lineTo(offsetTrue + deltaLength / 2 + deltaCorner / 2,
            size.height + deltaHeight);
        path.arcToPoint(
          Offset(offsetTrue + deltaLength / 2 - deltaCorner / 2,
              size.height + deltaHeight),
          radius: Radius.circular(arrowRadius),
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
