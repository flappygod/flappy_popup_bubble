import 'package:flutter/cupertino.dart';
import 'dart:ui';

///磨砂玻璃覆盖层view
class BubbleHover extends StatelessWidget {
  ///颜色
  final Color hoverColor;

  const BubbleHover({
    super.key,
    required this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return BubbleHoverBlurView(
      blur: true,
      color: hoverColor,
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: const SizedBox(width: double.infinity, height: double.infinity),
    );
  }
}

///磨砂玻璃效果hover view
class BubbleHoverBlurView extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final double? height;
  final double? width;
  final bool blur;
  final ImageFilter? filter;

  const BubbleHoverBlurView({
    super.key,
    required this.child,
    this.color,
    this.decoration,
    this.blur = false,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    ///如果需要模糊效果，构建模糊视图；否则直接返回普通容器
    return blur ? _buildBlurView() : _buildBaseContainer();
  }

  /// 构建模糊视图
  Widget _buildBlurView() {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: filter ?? ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: _buildBaseContainer(),
      ),
    );
  }

  /// 构建基础容器
  Widget _buildBaseContainer() {
    return Container(
      decoration: decoration,
      color: color,
      width: width,
      height: height,
      padding: padding,
      child: child,
    );
  }
}
