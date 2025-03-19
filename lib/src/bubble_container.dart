import 'package:flutter/material.dart';
import 'bubble_painter.dart';

class BubbleContainer extends StatelessWidget {
  ///padding
  final EdgeInsetsGeometry? padding;

  ///margin
  final EdgeInsetsGeometry? margin;

  ///alignment
  final AlignmentGeometry? alignment;

  ///constraints
  final BoxConstraints? constraints;

  ///left
  final BubbleType type;

  ///radius
  final BorderRadius radius;

  ///color
  final Color color;

  ///offset of bubble
  final double deltaOffset;

  ///delta length
  final double deltaLength;

  ///delta height
  final double deltaHeight;

  ///delta length
  final double deltaCorner;

  ///width and height
  final double? width;
  final double? height;
  final Widget? child;

  final Color? shadowColor;
  final double shadowElevation;
  final bool shadowOccluder;

  const BubbleContainer({
    super.key,
    this.padding,
    this.margin,
    this.alignment,
    this.radius = const BorderRadius.all(Radius.circular(5)),
    this.color = Colors.white,
    this.type = BubbleType.bottom,
    this.deltaOffset = 20,
    this.deltaLength = 10,
    this.deltaHeight = 6,
    this.deltaCorner = 2,
    this.width,
    this.height,
    this.child,
    this.constraints,
    this.shadowColor,
    this.shadowElevation = 5,
    this.shadowOccluder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CustomPaint(
        painter: BubblePainter(
          radius: radius,
          color: color,
          type: type,
          deltaOffset: deltaOffset,
          deltaCorner: deltaCorner,
          deltaLength: deltaLength,
          deltaHeight: deltaHeight,
          shadowColor: shadowColor,
          shadowElevation: shadowElevation,
          shadowOccluder: shadowOccluder,
        ),
        child: Container(
          padding: padding,
          alignment: alignment,
          width: width,
          constraints: constraints,
          height: height,
          child: child,
        ),
      ),
    );
  }
}
