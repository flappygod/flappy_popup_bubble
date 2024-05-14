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

  const PopupMenuBtn({
    super.key,
    this.backgroundColor,
    this.text,
    this.icon,
    this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 40,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        alignment: Alignment.center,
        color: backgroundColor,
        child: Row(
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
