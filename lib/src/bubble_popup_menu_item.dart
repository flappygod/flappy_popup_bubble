import 'package:flutter/material.dart';

///pop menu item
class BubblePopupMenuAction extends StatelessWidget {
  ///text
  final String? text;

  ///text style
  final TextStyle? textStyle;

  ///最大多少行
  final int? maxLines;

  ///icon
  final Widget? icon;

  ///background color
  final Color? backgroundColor;

  ///on tap
  final VoidCallback? onTap;

  ///height
  final double width;

  ///height
  final double height;

  ///padding
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool enableSplash;

  const BubblePopupMenuAction({
    super.key,
    this.backgroundColor,
    this.text,
    this.textStyle,
    this.maxLines,
    this.icon,
    this.onTap,
    this.width = 160,
    this.height = 55,
    this.padding = const EdgeInsets.fromLTRB(10, 0, 10, 0),
    this.borderRadius,
    this.enableSplash = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget actionBody = InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      splashFactory: enableSplash ? null : NoSplash.splashFactory,
      splashColor: enableSplash ? null : Colors.transparent,
      highlightColor: enableSplash ? null : Colors.transparent,
      hoverColor: enableSplash ? null : Colors.transparent,
      focusColor: enableSplash ? null : Colors.transparent,
      child: Ink(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text ?? '',
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: textStyle ?? const TextStyle(color: Colors.black, fontSize: 13),
              ),
            ),
            icon ?? const SizedBox(),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: text ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
        child: actionBody,
      ),
    );
  }
}
