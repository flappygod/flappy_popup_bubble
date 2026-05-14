import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 气泡箭头所在方向
enum BubbleType {
  /// 箭头在左侧
  left,

  /// 箭头在顶部
  top,

  /// 箭头在右侧
  right,

  /// 箭头在底部
  bottom,
}

/// 用于绘制带箭头的气泡背景
///
/// 特性：
/// 1. 支持四个方向的箭头：left / top / right / bottom
/// 2. 支持圆角矩形主体
/// 3. 支持箭头圆角
/// 4. 支持柔和阴影
///
/// 性能优化点：
/// 1. 主 Paint 只初始化一次
/// 2. 阴影 Paint 只初始化一次
/// 3. arrowRadius 按需缓存
/// 4. 与 size 相关的 safeRadius / arrowStart / path 做缓存
class BubblePainter extends CustomPainter {
  /// 气泡箭头方向
  final BubbleType type;

  /// 气泡主体圆角
  final BorderRadius radius;

  /// 气泡填充颜色
  final Color color;

  /// 箭头中心偏移位置
  ///
  /// 含义取决于方向：
  /// - left / right：相对于竖直方向的位置
  /// - top / bottom：相对于水平方向的位置
  final double deltaOffset;

  /// 箭头高度
  ///
  /// 即箭头从主体边缘向外突出的距离
  final double deltaHeight;

  /// 箭头底边长度
  final double deltaLength;

  /// 箭头尖端圆角控制值
  final double deltaCorner;

  /// 阴影颜色
  final Color? shadowColor;

  /// 阴影强度
  final double shadowElevation;

  /// 主绘制 Paint
  ///
  /// 只在构造时初始化一次，避免每次 paint 都创建对象。
  late final Paint _paint;

  /// 第一层阴影 Paint（更近、更深）
  Paint? _shadowPaint1;

  /// 第二层阴影 Paint（更远、更浅）
  Paint? _shadowPaint2;

  /// 缓存箭头圆角半径
  ///
  /// 仅在首次访问时计算。
  double? _arrowRadius;

  /// 缓存最近一次绘制时的 size
  ///
  /// 因为 safeRadius / arrowStart / path 都依赖 size，
  /// 所以当 size 不变时可以直接复用缓存。
  Size? _cachedSize;

  /// 缓存安全圆角
  ///
  /// 防止 radius 超过当前 size 可承受范围。
  BorderRadius? _cachedSafeRadius;

  /// 缓存箭头起始位置
  double? _cachedArrowStart;

  /// 缓存最终绘制 Path
  Path? _cachedPath;

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
  }) {
    /// 初始化主体 Paint
    _paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = color;

    /// 初始化阴影 Paint
    _initShadowPaints();
  }

  /// 初始化阴影 Paint
  ///
  /// 只在构造时执行一次，避免在 paint() 中频繁创建 Paint。
  void _initShadowPaints() {
    if (shadowColor == null || shadowElevation <= 0) {
      return;
    }

    final Color base = shadowColor!;
    final double e = shadowElevation.clamp(0.0, 24.0);

    /// 第一层阴影：更近、更清晰
    final double blur1 = 1.5 + e * 0.6;

    /// 第二层阴影：更远、更柔和
    final double blur2 = 4.0 + e * 1.0;

    _shadowPaint1 = Paint()
      ..isAntiAlias = true
      ..color = base.withValues(alpha: (base.a * 0.18).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur1);

    _shadowPaint2 = Paint()
      ..isAntiAlias = true
      ..color = base.withValues(alpha: (base.a * 0.08).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur2);
  }

  /// 计算“安全圆角”
  ///
  /// 由于外部传入的 radius 可能超过当前 size 的一半，
  /// 所以这里会对每个角做 clamp，避免绘制异常。
  ///
  /// 结果会按 size 缓存。
  BorderRadius _safeRadius(Size size) {
    if (_cachedSize == size && _cachedSafeRadius != null) {
      return _cachedSafeRadius!;
    }

    final double maxX = size.width / 2;
    final double maxY = size.height / 2;

    Radius clampRadius(Radius r) {
      return Radius.elliptical(
        r.x.clamp(0.0, maxX),
        r.y.clamp(0.0, maxY),
      );
    }

    final BorderRadius result = BorderRadius.only(
      topLeft: clampRadius(radius.topLeft),
      topRight: clampRadius(radius.topRight),
      bottomLeft: clampRadius(radius.bottomLeft),
      bottomRight: clampRadius(radius.bottomRight),
    );

    _cachedSafeRadius = result;
    return result;
  }

  /// 获取箭头圆角半径
  ///
  /// 只在首次访问时计算一次。
  double get arrowRadius {
    _arrowRadius ??= _computeArrowRadius();
    return _arrowRadius!;
  }

  /// 计算箭头圆角半径
  ///
  /// 这里根据箭头底边长度、箭头高度、箭头圆角值，
  /// 推导出 arcToPoint 所需的圆弧半径。
  double _computeArrowRadius() {
    final double safeCorner = deltaCorner.clamp(0.0, deltaLength);
    final double safeHeight = deltaHeight.abs();

    /// 没有圆角时，直接返回 0
    if (safeCorner <= 0) {
      return 0;
    }

    /// 高度极小时，退化处理
    if (safeHeight <= 0.0001) {
      return safeCorner / 2;
    }

    final double halfBase = math.max(0.0, (deltaLength - safeCorner) / 2);
    final double angle = math.atan(halfBase / safeHeight);
    final double cosValue = math.cos(angle);

    /// 避免极端情况下除以接近 0 的值
    if (cosValue.abs() <= 0.0001) {
      return safeCorner / 2;
    }

    return (safeCorner / 2) / cosValue;
  }

  /// 计算箭头起始位置，并限制在合法范围内
  ///
  /// 例如：
  /// - top / bottom：箭头沿 x 轴移动
  /// - left / right：箭头沿 y 轴移动
  ///
  /// 结果会按 size 缓存。
  double _clampArrowStart(Size size) {
    if (_cachedSize == size && _cachedArrowStart != null) {
      return _cachedArrowStart!;
    }

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

    final double result = start.clamp(0.0, maxStart);
    _cachedArrowStart = result;
    return result;
  }

  /// 获取或构建当前 size 对应的 Path
  ///
  /// 如果 size 没变，并且 path 已缓存，则直接复用。
  Path _getOrBuildPath(Size size) {
    if (_cachedSize == size && _cachedPath != null) {
      return _cachedPath!;
    }

    /// size 变化后，清空与 size 相关的缓存
    _cachedSize = size;
    _cachedSafeRadius = null;
    _cachedArrowStart = null;

    final double offsetTrue = _clampArrowStart(size);
    final Path path = _buildArrowPath(size, offsetTrue);

    _cachedPath = path;
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    /// 空尺寸直接不绘制
    if (size.isEmpty) {
      return;
    }

    /// 获取气泡路径
    final Path bubblePath = _getOrBuildPath(size);

    /// 先绘制阴影，再绘制主体
    if (_shadowPaint1 != null && _shadowPaint2 != null) {
      _paintSoftShadow(canvas, bubblePath);
    }

    canvas.drawPath(bubblePath, _paint);
  }

  /// 绘制柔和阴影
  ///
  /// 使用两层不同 blur 和透明度的阴影叠加，
  /// 让阴影更自然。
  void _paintSoftShadow(Canvas canvas, Path path) {
    final double e = shadowElevation.clamp(0.0, 24.0);

    /// 第一层阴影偏移
    final double dy1 = 0.5 + e * 0.12;

    /// 第二层阴影偏移
    final double dy2 = 1.5 + e * 0.18;

    /// 先画更远更淡的一层
    canvas.save();
    canvas.translate(0, dy2);
    canvas.drawPath(path, _shadowPaint2!);
    canvas.restore();

    /// 再画更近更深的一层
    canvas.save();
    canvas.translate(0, dy1);
    canvas.drawPath(path, _shadowPaint1!);
    canvas.restore();
  }

  /// 根据方向构建气泡 Path
  ///
  /// 参数 [deltaOffset] 是已经过 clamp 后的箭头起始位置。
  Path _buildArrowPath(Size size, double deltaOffset) {
    final BorderRadius safeRadius = _safeRadius(size);
    final Path path = Path();

    final double safeLength = math.max(0.0, deltaLength);
    final double safeHeight = math.max(0.0, deltaHeight);
    final double safeCorner = deltaCorner.clamp(0.0, safeLength);

    switch (type) {
      case BubbleType.left:

        /// 从左侧箭头尖端附近开始绘制
        path.moveTo(
          -safeHeight,
          deltaOffset + safeLength / 2 + safeCorner / 2,
        );

        /// 绘制箭头圆角
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

        /// 左上区域处理
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

        /// 上边 -> 右上角
        path.lineTo(size.width - safeRadius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, safeRadius.topRight.y),
          radius: safeRadius.topRight,
          clockwise: true,
        );

        /// 右边 -> 右下角
        path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - safeRadius.bottomRight.x, size.height),
          radius: safeRadius.bottomRight,
          clockwise: true,
        );

        /// 下边 -> 左下角 / 箭头连接
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

        /// 从顶部箭头尖端附近开始绘制
        path.moveTo(
          deltaOffset + safeLength / 2 - safeCorner / 2,
          -safeHeight,
        );

        /// 绘制箭头圆角
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

        /// 顶边 -> 右上角 / 箭头连接
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

        /// 右边 -> 右下角
        path.lineTo(size.width, size.height - safeRadius.bottomRight.y);
        path.arcToPoint(
          Offset(size.width - safeRadius.bottomRight.x, size.height),
          radius: safeRadius.bottomRight,
          clockwise: true,
        );

        /// 下边 -> 左下角
        path.lineTo(safeRadius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - safeRadius.bottomLeft.y),
          radius: safeRadius.bottomLeft,
          clockwise: true,
        );

        /// 左边
        path.lineTo(0, safeRadius.topLeft.y);

        /// 左上角 / 箭头连接
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

        /// 从右侧箭头尖端附近开始绘制
        path.moveTo(
          size.width + safeHeight,
          deltaOffset + safeLength / 2 - safeCorner / 2,
        );

        /// 绘制箭头圆角
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

        /// 右下区域处理
        if (deltaOffset + safeLength >=
            size.height - safeRadius.bottomRight.y) {
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

        /// 下边 -> 左下角
        path.lineTo(safeRadius.bottomLeft.x, size.height);
        path.arcToPoint(
          Offset(0, size.height - safeRadius.bottomLeft.y),
          radius: safeRadius.bottomLeft,
          clockwise: true,
        );

        /// 左边 -> 左上角
        path.lineTo(0, safeRadius.topLeft.y);
        path.arcToPoint(
          Offset(safeRadius.topLeft.x, 0),
          radius: safeRadius.topLeft,
          clockwise: true,
        );

        /// 上边 -> 右上角 / 箭头连接
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

        /// 从底部箭头尖端附近开始绘制
        path.moveTo(
          deltaOffset + safeLength / 2 + safeCorner / 2,
          size.height + safeHeight,
        );

        /// 绘制箭头圆角
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

        /// 底边 -> 左下角 / 箭头连接
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

        /// 左边 -> 左上角
        path.lineTo(0, safeRadius.topLeft.y);
        path.arcToPoint(
          Offset(safeRadius.topLeft.x, 0),
          radius: safeRadius.topLeft,
          clockwise: true,
        );

        /// 上边 -> 右上角
        path.lineTo(size.width - safeRadius.topRight.x, 0);
        path.arcToPoint(
          Offset(size.width, safeRadius.topRight.y),
          radius: safeRadius.topRight,
          clockwise: true,
        );

        /// 右边 -> 右下角 / 箭头连接
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
    /// 只有影响绘制结果的参数变化时，才触发重绘
    return oldDelegate.type != type ||
        oldDelegate.deltaCorner != deltaCorner ||
        oldDelegate.deltaOffset != deltaOffset ||
        oldDelegate.deltaHeight != deltaHeight ||
        oldDelegate.deltaLength != deltaLength ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowElevation != shadowElevation;
  }
}
