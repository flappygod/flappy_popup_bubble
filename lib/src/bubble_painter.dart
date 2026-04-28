import 'package:flutter/material.dart';
import 'dart:math' as math;

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

  /// Offset of the bubble's arrow center
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
    this.shadowElevation = 3.5,
  }) : _paint = Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = color;

  BorderRadius _safeRadius(Size size) {
    final double maxX = size.width / 2;
    final double maxY = size.height / 2;

    Radius clampRadius(Radius r) {
      return Radius.elliptical(
        r.x.clamp(0.0, maxX),
        r.y.clamp(0.0, maxY),
      );
    }

    return BorderRadius.only(
      topLeft: clampRadius(radius.topLeft),
      topRight: clampRadius(radius.topRight),
      bottomLeft: clampRadius(radius.bottomLeft),
      bottomRight: clampRadius(radius.bottomRight),
    );
  }

  /// Get the arrow radius, calculate only when necessary
  double get arrowRadius {
    _arrowRadius ??= _computeArrowRadius();
    return _arrowRadius!;
  }

  /// compute arrow radius
  double _computeArrowRadius() {
    final double safeCorner = deltaCorner.clamp(0.0, deltaLength);
    final double safeHeight = deltaHeight.abs();
    if (safeCorner <= 0) {
      return 0;
    }
    if (safeHeight <= 0.0001) {
      return safeCorner / 2;
    }
    final double halfBase = math.max(0.0, (deltaLength - safeCorner) / 2);
    final double angle = math.atan(halfBase / safeHeight);
    final double cosValue = math.cos(angle);
    if (cosValue.abs() <= 0.0001) {
      return safeCorner / 2;
    }
    return (safeCorner / 2) / cosValue;
  }

  ///clamp arrow start
  double _clampArrowStart(Size size) {
    final double safeLength = math.max(0.0, deltaLength);
    double start = deltaOffset - safeLength / 2;
    final double maxStart;
    switch (type) {
      case BubbleType.left:
      case BubbleType.right:
        maxStart = math.max(0.0, size.height - safeLength);
        break;
      case BubbleType.top:
      case BubbleType.bottom:
        maxStart = math.max(0.0, size.width - safeLength);
        break;
    }
    return start.clamp(0.0, maxStart);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final double offsetTrue = _clampArrowStart(size);
    final Path bubblePath = _buildArrowPath(size, offsetTrue);
    if (shadowColor != null && shadowElevation > 0) {
      _paintSoftShadow(canvas, bubblePath);
    }
    canvas.drawPath(bubblePath, _paint);
  }

  void _paintSoftShadow(Canvas canvas, Path path) {
    final Color base = shadowColor!;
    final double e = shadowElevation.clamp(0.0, 24.0);
    final double blur1 = 1.5 + e * 0.6;
    final double blur2 = 4.0 + e * 1.0;
    final double dy1 = 0.5 + e * 0.12;
    final double dy2 = 1.5 + e * 0.18;

    final Paint shadowPaint1 = Paint()
      ..isAntiAlias = true
      ..color = base.withValues(alpha: (base.a * 0.18).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur1);

    final Paint shadowPaint2 = Paint()
      ..isAntiAlias = true
      ..color = base.withValues(alpha: (base.a * 0.08).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur2);

    canvas.save();
    canvas.translate(0, dy2);
    canvas.drawPath(path, shadowPaint2);
    canvas.restore();

    canvas.save();
    canvas.translate(0, dy1);
    canvas.drawPath(path, shadowPaint1);
    canvas.restore();
  }

  /// Build the arrow path based on the bubble type
  Path _buildArrowPath(Size size, double deltaOffset) {
    final BorderRadius safeRadius = _safeRadius(size);
    final Path path = Path();

    final double safeLength = math.max(0.0, deltaLength);
    final double safeHeight = math.max(0.0, deltaHeight);
    final double safeCorner = deltaCorner.clamp(0.0, safeLength);

    switch (type) {
      case BubbleType.left:
        path.moveTo(
          -safeHeight,
          deltaOffset + safeLength / 2 + safeCorner / 2,
        );
        if (safeCorner > 0) {
          path.arcToPoint(
            Offset(
              -safeHeight,
              deltaOffset + safeLength / 2 - safeCorner / 2,
            ),
            radius: Radius.circular(arrowRadius),
            clockwise: true,
          );
        }

        if (deltaOffset <= safeRadius.topLeft.y) {
          path.lineTo(safeRadius.topLeft.x, 0);
          path.lineTo(0, safeRadius.topLeft.y);
          path.arcToPoint(
            Offset(safeRadius.topLeft.x, 0),
            radius: safeRadius.topLeft,
            clockwise: true,
          );
        } else {
          path.lineTo(0, deltaOffset);
          path.lineTo(0, safeRadius.topLeft.y);
          path.arcToPoint(
            Offset(safeRadius.topLeft.x, 0),
            radius: safeRadius.topLeft,
            clockwise: true,
          );
        }

        path.lineTo(size.width - safeRadius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, safeRadius.topRight.y),
          radius: safeRadius.topRight,
          clockwise: true,
        );
        path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - safeRadius.bottomRight.x, size.height),
          radius: safeRadius.bottomRight,
          clockwise: true,
        );
        path.lineTo(safeRadius.bottomLeft.x, size.height);
        if (deltaOffset + safeLength >= size.height - safeRadius.bottomLeft.y) {
          path.lineTo(
            -safeHeight,
            deltaOffset + safeLength / 2 + safeCorner / 2,
          );
          path.lineTo(0, size.height - safeRadius.bottomLeft.y);
          path.lineTo(safeRadius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - safeRadius.bottomLeft.y),
            radius: safeRadius.bottomLeft,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(0, size.height - safeRadius.bottomLeft.y),
            radius: safeRadius.bottomLeft,
            clockwise: true,
          );
          path.lineTo(0, deltaOffset + safeLength);
        }
        path.close();
        break;

      case BubbleType.top:
        path.moveTo(
          deltaOffset + safeLength / 2 - safeCorner / 2,
          -safeHeight,
        );
        if (safeCorner > 0) {
          path.arcToPoint(
            Offset(
              deltaOffset + safeLength / 2 + safeCorner / 2,
              -safeHeight,
            ),
            radius: Radius.circular(arrowRadius),
            clockwise: true,
          );
        }

        if (deltaOffset + safeLength >= size.width - safeRadius.topRight.x) {
          path.lineTo(size.width, safeRadius.topRight.y);
          path.lineTo(size.width - safeRadius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, safeRadius.topRight.y),
            radius: safeRadius.topRight,
            clockwise: true,
          );
        } else {
          path.lineTo(deltaOffset + safeLength, 0);
          path.lineTo(size.width - safeRadius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, safeRadius.topRight.y),
            radius: safeRadius.topRight,
            clockwise: true,
          );
        }

        path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - safeRadius.bottomRight.x, size.height),
          radius: safeRadius.bottomRight,
          clockwise: true,
        );
        path.lineTo(safeRadius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - safeRadius.bottomLeft.y),
          radius: safeRadius.bottomLeft,
          clockwise: true,
        );
        path.lineTo(0, safeRadius.topLeft.y);

        if (deltaOffset <= safeRadius.topLeft.x) {
          path.lineTo(
            deltaOffset + safeLength / 2 - safeCorner / 2,
            -safeHeight,
          );
          path.lineTo(safeRadius.topLeft.x, 0);
          path.lineTo(0, safeRadius.topLeft.y);
          path.arcToPoint(
            Offset(safeRadius.topLeft.x, 0),
            radius: safeRadius.topLeft,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(safeRadius.topLeft.x, 0),
            radius: safeRadius.topLeft,
            clockwise: true,
          );
          path.lineTo(deltaOffset, 0);
        }
        path.close();
        break;

      case BubbleType.right:
        path.moveTo(
          size.width + safeHeight,
          deltaOffset + safeLength / 2 - safeCorner / 2,
        );
        if (safeCorner > 0) {
          path.arcToPoint(
            Offset(
              size.width + safeHeight,
              deltaOffset + safeLength / 2 + safeCorner / 2,
            ),
            radius: Radius.circular(arrowRadius),
            clockwise: true,
          );
        }
        if (deltaOffset + safeLength >= size.height - safeRadius.bottomRight.y) {
          path.lineTo(size.width - safeRadius.bottomRight.x, size.height);
          path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - safeRadius.bottomRight.x, size.height),
            radius: safeRadius.bottomRight,
            clockwise: true,
          );
        } else {
          path.lineTo(size.width, deltaOffset + safeLength);
          path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - safeRadius.bottomRight.x, size.height),
            radius: safeRadius.bottomRight,
            clockwise: true,
          );
        }
        path.lineTo(safeRadius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - safeRadius.bottomLeft.y),
          radius: safeRadius.bottomLeft,
          clockwise: true,
        );
        path.lineTo(0, safeRadius.topLeft.y);
        path.arcToPoint(
          Offset(safeRadius.topLeft.x, 0),
          radius: safeRadius.topLeft,
          clockwise: true,
        );
        path.lineTo(size.width - safeRadius.topRight.x, 0);
        if (deltaOffset <= safeRadius.topRight.y) {
          path.lineTo(
            size.width + safeHeight,
            deltaOffset + safeLength / 2 - safeCorner / 2,
          );
          path.lineTo(size.width, safeRadius.topRight.y);
          path.lineTo(size.width - safeRadius.topRight.x, 0);
          path.arcToPoint(
            Offset(size.width, safeRadius.topRight.y),
            radius: safeRadius.topRight,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(size.width, safeRadius.topRight.y),
            radius: safeRadius.topRight,
            clockwise: true,
          );
          path.lineTo(size.width, deltaOffset);
        }
        path.close();
        break;

      case BubbleType.bottom:
        path.moveTo(
          deltaOffset + safeLength / 2 + safeCorner / 2,
          size.height + safeHeight,
        );
        if (safeCorner > 0) {
          path.arcToPoint(
            Offset(
              deltaOffset + safeLength / 2 - safeCorner / 2,
              size.height + safeHeight,
            ),
            radius: Radius.circular(arrowRadius),
            clockwise: true,
          );
        }
        if (deltaOffset <= safeRadius.bottomLeft.x) {
          path.lineTo(0, size.height - safeRadius.bottomLeft.y);
          path.lineTo(safeRadius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - safeRadius.bottomLeft.y),
            radius: safeRadius.bottomLeft,
            clockwise: true,
          );
        } else {
          path.lineTo(deltaOffset, size.height);
          path.lineTo(safeRadius.bottomLeft.x, size.height);
          path.arcToPoint(
            Offset(0, size.height - safeRadius.bottomLeft.y),
            radius: safeRadius.bottomLeft,
            clockwise: true,
          );
        }
        path.lineTo(0, safeRadius.topLeft.y);
        path.arcToPoint(
          Offset(safeRadius.topLeft.x, 0),
          radius: safeRadius.topLeft,
          clockwise: true,
        );
        path.lineTo(size.width - safeRadius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, safeRadius.topRight.y),
          radius: safeRadius.topRight,
          clockwise: true,
        );
        path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
        if (deltaOffset + safeLength >= size.width - safeRadius.bottomRight.x) {
          path.lineTo(
            deltaOffset + safeLength / 2 + safeCorner / 2,
            size.height + safeHeight,
          );
          path.lineTo(size.width - safeRadius.bottomRight.x, size.height);
          path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
          path.arcToPoint(
            Offset(size.width - safeRadius.bottomRight.x, size.height),
            radius: safeRadius.bottomRight,
            clockwise: true,
          );
        } else {
          path.arcToPoint(
            Offset(size.width - safeRadius.bottomRight.x, size.height),
            radius: safeRadius.bottomRight,
            clockwise: true,
          );
          path.lineTo(deltaOffset + safeLength, size.height);
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
        oldDelegate.radius != radius ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowElevation != shadowElevation;
    if (needsRepaint &&
        (oldDelegate.deltaCorner != deltaCorner ||
            oldDelegate.deltaLength != deltaLength ||
            oldDelegate.deltaHeight != deltaHeight)) {
      _arrowRadius = null;
    }
    return needsRepaint;
  }
}
