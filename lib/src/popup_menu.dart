import 'package:flutter/material.dart';
import 'popup_animation.dart';
import 'bubble_container.dart';
import 'bubble_painter.dart';

///build menu
typedef PopupMenuBuilder = List<Widget> Function(
    BuildContext context, PopupMenuController controller);

///pop feed animation alpha controller
class PopupMenuController {
  static const int _eventShow = 1;
  static const int _eventHide = 2;

  final List<ValueChanged<int>> _listeners = [];

  ///show menu
  void show() {
    notifyListeners(_eventShow);
  }

  ///hide menu
  void hide() {
    notifyListeners(_eventHide);
  }

  //notify listener
  void notifyListeners(int data) {
    for (ValueChanged<int> item in _listeners) {
      item(data);
    }
  }

  void addListener(ValueChanged<int> listener) {
    _listeners.add(listener);
  }

  void removeListener(ValueChanged<int> listener) {
    _listeners.remove(listener);
  }
}

///add popup menu
class PopupMenu extends StatefulWidget {
  ///controller
  final PopupMenuController? controller;

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

  final double? offsetDx;
  final double? offsetDy;

  ///translucent
  final bool translucent;

  ///show on long press
  final bool showOnLongPress;

  ///touch to close
  final bool touchToClose;

  const PopupMenu({
    super.key,
    this.controller,
    required this.child,
    required this.menusBuilder,
    this.menuWidth = 120,
    this.menuHeight = 40,
    this.backgroundColor = const Color(0xFF5A5B5E),
    this.dividerColor = Colors.black87,
    this.translucent = false,
    this.showOnLongPress = true,
    this.touchToClose = true,
    this.offsetDx,
    this.offsetDy,
  });

  @override
  State<StatefulWidget> createState() {
    return _PopupMenuState();
  }
}

class _PopupMenuState extends State<PopupMenu> {
  ///menu controller
  PopupMenuController? _menuController;

  ///listener
  late ValueChanged<int> _listener;

  ///controller
  final PopupAnimationController _animationController =
      PopupAnimationController();

  ///global key
  final GlobalKey _globalKey = GlobalKey();

  ///overlay is show or not
  OverlayEntry? _currentShowOverlay;

  @override
  void initState() {
    _menuController = widget.controller ?? PopupMenuController();
    _listener = (event) {
      if (event == PopupMenuController._eventHide) {
        _hideOverlay();
      }
      if (event == PopupMenuController._eventShow) {
        _showOverlay();
      }
    };
    _menuController?.addListener(_listener);
    super.initState();
  }

  @override
  void didUpdateWidget(PopupMenu oldWidget) {
    if (widget.controller != null && widget.controller != _menuController) {
      _menuController?.removeListener(_listener);
      _menuController = widget.controller;
      _menuController?.addListener(_listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _globalKey,
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        if (widget.showOnLongPress) {
          _menuController?.show();
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _menuController?.removeListener(_listener);
    _animationController.hide();
    super.dispose();
  }

  ///show overlay
  void _showOverlay() {
    ///if overlay is not show ,show overlay
    if (_currentShowOverlay == null) {
      final OverlayState overlay = Overlay.of(context);
      _currentShowOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: 0,
          top: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: _buildPopUpMenu(),
        ),
      );
      overlay.insert(_currentShowOverlay!);
      _animationController.show();
    }
  }

  ///hide overlay
  void _hideOverlay() {
    _animationController.hide();
  }

  ///divider height
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
  List<Widget> createListWithSeparators(
      List<Widget> originalList, Widget separator) {
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
  Widget _buildPopUpMenu() {
    ///use material for hole
    return widget.translucent
        ? _buildContent()
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.touchToClose) {
                _hideOverlay();
              }
            },
            child: _buildContent(),
          );
  }

  ///build content
  Widget _buildContent() {
    ///get render box
    ///get render box
    RenderBox? renderBox =
        _globalKey.currentContext?.findRenderObject() as RenderBox?;

    ///context is null
    if (renderBox == null) {
      return const SizedBox();
    }

    ///offset
    final offset = renderBox.localToGlobal(Offset.zero);

    ///build menus
    List<Widget> menusWidgets = widget.menusBuilder(context, _menuController!);

    ///menus
    List<Widget> menus =
        createListWithSeparators(menusWidgets, _buildDivider());

    ///width and height
    double menuWidth = widget.menuWidth;
    double menuHeight =
        (widget.menuHeight + _getDividerHeight()) * menusWidgets.length;

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

    ///removed
    if (offset.dx > bigRect.width) {
      return const SizedBox();
    }

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,

      ///use stack for the popup
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ///use position
          Positioned(
            left: posLimit.dx - (widget.offsetDx ?? 0),
            top: posLimit.dy - (widget.offsetDy ?? 0),
            child: PopupAnimation(
              controller: _animationController,
              onHide: () {
                ///remove overlay
                _currentShowOverlay?.remove();
                _currentShowOverlay = null;
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
    );
  }

  ///build constrain rect
  Offset constrainRectWithinRect(
      Rect bigRect, Rect smallRect, Offset smallRectOffset) {
    // 计算小 Rect 右下角的 Offset
    Offset smallRectBottomRight =
        smallRectOffset + Offset(smallRect.width, smallRect.height);

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
