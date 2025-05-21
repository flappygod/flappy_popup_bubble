import 'package:flutter/material.dart';

///pop menu item
class PopupMenuBtn extends StatelessWidget {
  ///text
  final String? text;

  ///text style
  final TextStyle? textStyle;

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
  final EdgeInsets? padding;

  const PopupMenuBtn({
    super.key,
    this.backgroundColor,
    this.text,
    this.icon,
    this.textStyle,
    this.onTap,
    this.width = 200,
    this.height = 40,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.fromLTRB(10, 0, 10, 0),
        alignment: Alignment.center,
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text ?? '',
                style: textStyle ??
                    const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            icon ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
