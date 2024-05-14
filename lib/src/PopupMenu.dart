import 'package:flutter/material.dart';
import 'PopupFeedAnimation.dart';
import 'BubbleContainer.dart';
import 'BubblePainter.dart';

///build menu
typedef PopupMenuBuilder = List<Widget> Function(BuildContext context, PopupMenuController controller);

///add popup menu
class PopupMenu extends StatefulWidget {
  ///background color
  final Color backgroundColor;

  ///divider
  final Color dividerColor;

  ///menu width
  final double menuWidth;

  ///menu width
  final double menuHeight;

  ///child widget
  final Widget child;

  ///menus
  final PopupMenuBuilder menusBuilder;

  const PopupMenu({
    super.key,
    required this.child,
    required this.menusBuilder,
    this.menuWidth = 120,
    this.menuHeight = 40,
    this.backgroundColor = const Color(0xFF5A5B5E),
    this.dividerColor = Colors.black87,
  });

  @override
  State<StatefulWidget> createState() {
    return _PopupMenuState();
  }
}

class _PopupMenuState extends State<PopupMenu> {
  ///controller
  final PopupMenuController _controller = PopupMenuController();

  ///global key
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _globalKey,
      behavior: HitTestBehavior.translucent,
      onLongPress: _showOverlay,
      child: widget.child,
    );
  }

  ///show overlay
  void _showOverlay() {
    ///build overlay
    final OverlayState overlay = Overlay.of(context);

    ///创建一个 OverlayEntry 对象
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: _buildPopUpMenu(overlayEntry),
      ),
    );
    overlay.insert(overlayEntry);
  }

  ///divider
  double _getDividerHeight() {
    return 1 / MediaQuery.of(context).devicePixelRatio;
  }

  ///build divider
  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: _getDividerHeight(),
      color: widget.dividerColor,
    );
  }

  ///build Separators
  List<Widget> createListWithSeparators(List<Widget> originalList, Widget separator) {
    List<Widget> listWithSeparators = [];
    for (int i = 0; i < originalList.length; i++) {
      listWithSeparators.add(originalList[i]);
      if (i < originalList.length - 1) {
        listWithSeparators.add(separator);
      }
    }
    return listWithSeparators;
  }

  ///build pop up member
  Widget _buildPopUpMenu(OverlayEntry? overlayEntry) {
    ///get render box
    RenderBox renderBox = _globalKey.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    ///build menus
    List<Widget> menusWidgets = widget.menusBuilder(context, _controller);

    ///menus
    List<Widget> menus = createListWithSeparators(menusWidgets, _buildDivider());

    ///width and height
    double menuWidth = widget.menuWidth;
    double menuHeight = (widget.menuHeight + _getDividerHeight()) * menusWidgets.length;

    ///get the container rect
    Rect bigRect = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );

    ///limit the rect
    Rect smallRect = Rect.fromLTWH(
      0,
      0,
      menuWidth,
      menuHeight,
    );

    bool showDown = true;

    ///get left and top
    Offset pos = Offset(
      offset.dx - widget.menuWidth / 2 + renderBox.size.width / 2,
      offset.dy + renderBox.size.height + 10,
    );

    ///up or down
    if (pos.dy + menuHeight + 100 > bigRect.height) {
      showDown = false;

      ///get left and top
      pos = Offset(
        offset.dx - widget.menuWidth / 2 + renderBox.size.width / 2,
        offset.dy - menuHeight - 10,
      );
    }

    ///pos limit
    Offset posLimit = constrainRectWithinRect(bigRect, smallRect, pos);

    ///delta offset
    double delta = ((pos.dx + widget.menuWidth / 2) - posLimit.dx);

    ///use material for hole
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _controller.hide();
      },
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,

        ///use stack for the popup
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ///use position
            Positioned(
              left: posLimit.dx,
              top: posLimit.dy,
              child: PopupFeedAnimation(
                controller: _controller,
                onHide: () {
                  ///remove overlay
                  overlayEntry?.remove();
                },
                child: BubbleContainer(
                  width: widget.menuWidth,
                  type: showDown ? BubbleType.top : BubbleType.bottom,
                  radius: BorderRadius.circular(8),
                  deltaOffset: delta,
                  color: widget.backgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: menus,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///build constrain rect
  Offset constrainRectWithinRect(Rect bigRect, Rect smallRect, Offset smallRectOffset) {
    // 计算小 Rect 右下角的 Offset
    Offset smallRectBottomRight = smallRectOffset + Offset(smallRect.width, smallRect.height);

    // 计算小 Rect 能够移动的最大 Offset
    double maxDx = bigRect.right - smallRect.width;
    double maxDy = bigRect.bottom - smallRect.height;

    // 确保小 Rect 的左上角 Offset 不会超出大 Rect 的边界
    double newDx = smallRectOffset.dx.clamp(bigRect.left, maxDx);
    double newDy = smallRectOffset.dy.clamp(bigRect.top, maxDy);

    // 确保小 Rect 的右下角 Offset 也不会超出大 Rect 的边界
    if (smallRectBottomRight.dx > bigRect.right) {
      newDx = bigRect.right - smallRect.width;
    }
    if (smallRectBottomRight.dy > bigRect.bottom) {
      newDy = bigRect.bottom - smallRect.height;
    }

    return Offset(newDx, newDy);
  }
}
