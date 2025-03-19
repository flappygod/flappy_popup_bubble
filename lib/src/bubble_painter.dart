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

  final Color? shadowColor;
  final double shadowElevation;
  final bool shadowOccluder;

  /// Cached arrow radius
  double? _arrowRadius;

  BubblePainter({
    this.radius = const BorderRadius.all(Radius.circular(5)),
    this.color = Colors.white70,
    this.type = BubbleType.bottom,
    required this.deltaOffset,
    required this.deltaLength,
    required this.deltaHeight,
    required this.deltaCorner,
    this.shadowColor,
    this.shadowElevation = 5,
    this.shadowOccluder = true,
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

    if (shadowColor != null) {
      canvas.drawShadow(
        arrowPath,
        shadowColor!,
        shadowElevation,
        shadowOccluder,
      );
    }
  }

  /// Build the arrow path based on the bubble type
  Path _buildArrowPath(Size size, double deltaOffset) {
    final Path path = Path();

    switch (type) {
      case BubbleType.left:
        path.moveTo(
            -deltaHeight, deltaOffset + deltaLength / 2 + deltaCorner / 2);
        path.arcToPoint(
          Offset(-deltaHeight, deltaOffset + deltaLength / 2 - deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        if (deltaOffset <= radius.topLeft.y) {
          path.lineTo(radius.topLeft.x, 0);
          path.lineTo(0, radius.topLeft.y);
          path.arcToPoint(
            Offset(radius.topLeft.x, 0),
            radius: radius.topLeft,
            clockwise: true,
          );
        } else {
          path.lineTo(0, deltaOffset);
          path.lineTo(0, radius.topLeft.y);
          path.arcToPoint(
            Offset(radius.topLeft.x, 0),
            radius: radius.topLeft,
            clockwise: true,
          );
        }
        path.lineTo(size.width - radius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, radius.topRight.y),
          radius: radius.topRight,
          clockwise: true,
        );
        path.lineTo(size.width, size.height - radius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - radius.bottomRight.x, size.height),
          radius: radius.bottomRight,
          clockwise: true,
        );
        path.lineTo(radius.bottomLeft.x, size.height);
        if (deltaOffset + deltaLength >= size.height - radius.bottomLeft.y) {
          path.lineTo(
              -deltaHeight, deltaOffset + deltaLength / 2 + deltaCorner / 2);
          path.lineTo(0, size.height - radius.bottomLeft.y);
          path.lineTo(radius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - radius.bottomLeft.y),
            radius: radius.bottomLeft,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(0, size.height - radius.bottomLeft.y),
            radius: radius.bottomLeft,
            clockwise: true,
          );
          path.lineTo(0, deltaOffset + deltaLength);
        }
        path.close();
        break;

      case BubbleType.top:
        path.moveTo(
            deltaOffset + deltaLength / 2 - deltaCorner / 2, -deltaHeight);
        path.arcToPoint(
          Offset(deltaOffset + deltaLength / 2 + deltaCorner / 2, -deltaHeight),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        if (deltaOffset + deltaLength >= size.width - radius.topRight.x) {
          path.lineTo(size.width, radius.topRight.y);
          path.lineTo(size.width - radius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, radius.topRight.y),
            radius: radius.topRight,
            clockwise: true,
          );
        } else {
          path.lineTo(deltaOffset + deltaLength, 0);
          path.lineTo(size.width - radius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, radius.topRight.y),
            radius: radius.topRight,
            clockwise: true,
          );
        }
        path.lineTo(size.width, size.height - radius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - radius.bottomRight.x, size.height),
          radius: radius.bottomRight,
          clockwise: true,
        );
        path.lineTo(radius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - radius.bottomLeft.y),
          radius: radius.bottomLeft,
          clockwise: true,
        );
        path.lineTo(0, radius.topLeft.y);
        if (deltaOffset <= radius.topLeft.x) {
          path.lineTo(
              deltaOffset + deltaLength / 2 - deltaCorner / 2, -deltaHeight);
          path.lineTo(radius.topLeft.x, 0);
          path.lineTo(0, radius.topLeft.y);
          path.arcToPoint(
            Offset(radius.topLeft.x, 0),
            radius: radius.topLeft,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(radius.topLeft.x, 0),
            radius: radius.topLeft,
            clockwise: true,
          );
          path.lineTo(deltaOffset, 0);
        }
        path.close();
        break;

      case BubbleType.right:
        path.moveTo(size.width + deltaHeight,
            deltaOffset + deltaLength / 2 - deltaCorner / 2);
        path.arcToPoint(
          Offset(size.width + deltaHeight,
              deltaOffset + deltaLength / 2 + deltaCorner / 2),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        if (deltaOffset + deltaLength >= size.height - radius.bottomRight.y) {
          path.lineTo(size.width - radius.bottomRight.x, size.height);
          path.lineTo(size.width, size.height - radius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - radius.bottomRight.x, size.height),
            radius: radius.bottomRight,
            clockwise: true,
          );
        } else {
          path.lineTo(size.width, deltaOffset + deltaLength);
          path.lineTo(size.width, size.height - radius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - radius.bottomRight.x, size.height),
            radius: radius.bottomRight,
            clockwise: true,
          );
        }
        path.lineTo(radius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - radius.bottomLeft.y),
          radius: radius.bottomLeft,
          clockwise: true,
        );
        path.lineTo(0, radius.topLeft.y);
        path.arcToPoint(
          Offset(radius.topLeft.x, 0),
          radius: radius.topLeft,
          clockwise: true,
        );
        path.lineTo(size.width - radius.topRight.x, 0);
        if (deltaOffset <= radius.topRight.y) {
          path.lineTo(size.width + deltaHeight,
              deltaOffset + deltaLength / 2 - deltaCorner / 2);
          path.lineTo(size.width, radius.topLeft.y);
          path.lineTo(size.width - radius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, radius.topRight.y),
            radius: radius.topRight,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(size.width, radius.topRight.y),
            radius: radius.topRight,
            clockwise: true,
          );
          path.lineTo(size.width, deltaOffset);
        }
        path.close();
        break;

      case BubbleType.bottom:
        path.moveTo(deltaOffset + deltaLength / 2 + deltaCorner / 2,
            size.height + deltaHeight);
        path.arcToPoint(
          Offset(deltaOffset + deltaLength / 2 - deltaCorner / 2,
              size.height + deltaHeight),
          radius: Radius.circular(arrowRadius),
          clockwise: true,
        );
        if (deltaOffset <= radius.bottomLeft.x) {
          path.lineTo(0, size.height - radius.bottomLeft.y);
          path.lineTo(radius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - radius.bottomLeft.y),
            radius: radius.bottomLeft,
            clockwise: true,
          );
        } else {
          path.lineTo(deltaOffset, size.height);
          path.lineTo(radius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - radius.bottomLeft.y),
            radius: radius.bottomLeft,
            clockwise: true,
          );
        }
        path.lineTo(0, radius.topLeft.y);
        path.arcToPoint(
          Offset(radius.topLeft.x, 0),
          radius: radius.topLeft,
          clockwise: true,
        );
        path.arcToPoint(
          Offset(radius.topLeft.x, 0),
          radius: radius.topLeft,
          clockwise: true,
        );
        path.lineTo(size.width - radius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, radius.topRight.y),
          radius: radius.topRight,
          clockwise: true,
        );
        path.lineTo(size.width, size.height - radius.bottomRight.y);
        if (deltaOffset + deltaLength >= size.width - radius.bottomRight.x) {
          path.lineTo(deltaOffset + deltaLength / 2 + deltaCorner / 2,
              size.height + deltaHeight);
          path.lineTo(size.width - radius.bottomRight.x, size.height);
          path.lineTo(size.width, size.height - radius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - radius.bottomRight.x, size.height),
            radius: radius.bottomRight,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(size.width - radius.bottomRight.x, size.height),
            radius: radius.bottomRight,
            clockwise: true,
          );
          path.lineTo(deltaOffset + deltaLength, size.height);
        }
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
