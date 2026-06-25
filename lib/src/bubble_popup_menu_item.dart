import 'package:flutter/material.dart';
import 'bubble_ink_well.dart';

///Popup menu item.
///
///基于 [PressableInkWell] 封装的气泡菜单操作项。
///主要负责菜单项的内容布局，点击反馈、语义和按下态由
///[PressableInkWell] 统一处理。
class BubblePopupMenuAction extends StatelessWidget {
  ///文本内容。
  final String? text;

  ///文本样式。
  final TextStyle? textStyle;

  ///文本最大行数。
  final int? maxLines;

  ///右侧图标。
  final Widget? icon;

  ///背景色。
  final Color? backgroundColor;

  ///点击回调。
  final VoidCallback? onTap;

  ///宽度。
  final double width;

  ///高度。
  final double height;

  ///内边距。
  final EdgeInsets padding;

  ///圆角。
  final BorderRadius? borderRadius;

  ///是否启用水波纹。
  final bool enableSplash;

  ///是否启用按下高亮。
  final bool enableHighlight;

  ///自定义按下高亮颜色。
  final Color? highlightColor;

  const BubblePopupMenuAction({
    super.key,
    this.backgroundColor,
    this.text,
    this.textStyle,
    this.maxLines,
    this.icon,
    this.onTap,
    this.width = 180,
    this.height = 50,
    this.padding = const EdgeInsets.fromLTRB(12.5, 0, 12.5, 0),
    this.borderRadius,
    this.enableSplash = false,
    this.enableHighlight = true,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return PressableInkWell(
      width: width,
      height: height,
      padding: padding,
      backgroundColor: backgroundColor ?? Colors.transparent,
      borderRadius: borderRadius,
      onTap: onTap,

      ///菜单项通常不需要明显水波纹，默认关闭。
      enableSplashEffect: enableSplash,

      ///是否启用按下态高亮。
      enablePressedEffect: enableHighlight,

      ///自定义按下态颜色。
      pressedColor: highlightColor,

      ///语义上声明为按钮，并使用文本作为朗读标签。
      semanticButton: true,
      semanticLabel: text ?? '',

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text ?? '',
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                  ),
            ),
          ),
          icon ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
