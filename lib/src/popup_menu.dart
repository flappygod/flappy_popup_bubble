import 'package:flutter/material.dart';
import 'bubble_container.dart';
import 'popup_animation.dart';
import 'bubble_painter.dart';

///type
enum PopupMenuTriggerType {
  onTap,
  onLongPress,
}

///build menu
typedef PopupMenuBuilder = List<Widget> Function(
    BuildContext context, PopupMenuController controller);

///pop feed animation alpha controller
class PopupMenuController {
  static const int _eventShow = 1;
  static const int _eventHide = 2;

  final List<ValueChanged<int>> _listeners = [];

  ///is show pop
  bool _isShowPop = false;

  ///show menu
  void show() {
    _isShowPop = true;
    notifyListeners(_eventShow);
  }

  ///hide menu
  void hide() {
    _isShowPop = false;
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

  ///show child on top or not
  final bool showChildTop;

  ///show on long press
  final PopupMenuTriggerType triggerType;

  ///content padding
  final EdgeInsets contentPadding;

  ///touch to close
  final bool barrierDismissible;

  ///radius
  final BorderRadius radius;

  ///shadows
  final Color? shadowColor;
  final double shadowElevation;
  final bool shadowOccluder;

  ///hover widget
  final Widget? hover;

  final Widget? subHead;
  final double? subHeadHeight;

  const PopupMenu({
    super.key,
    this.controller,
    required this.child,
    required this.menusBuilder,
    this.menuWidth = 120,
    this.menuHeight = 40,
    this.backgroundColor = const Color(0xFF5A5B5E),
    this.dividerColor = Colors.black87,
    this.triggerType = PopupMenuTriggerType.onLongPress,
    this.barrierDismissible = true,
    this.showChildTop = false,
    this.translucent = false,
    this.offsetDx,
    this.offsetDy,
    this.contentPadding = EdgeInsets.zero,
    this.shadowColor,
    this.shadowElevation = 5,
    this.shadowOccluder = true,
    this.radius = const BorderRadius.all(
      Radius.circular(8),
    ),
    this.hover,
    this.subHead,
    this.subHeadHeight,
  }) : assert((subHead == null && subHeadHeight == null) ||
            (subHead != null && subHeadHeight != null));

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

  ///controller
  final PopupAnimationController _animationHoverController =
      PopupAnimationController();

  ///global key
  final GlobalKey _currentKey = GlobalKey();
  Rect _currentRect = Rect.zero;
  bool _currentIsPop = false;

  ///overlay is show or not
  OverlayEntry? _currentShowOverlay;

  @override
  void initState() {
    _menuController = widget.controller ?? PopupMenuController();

    ///add listener
    _listener = (event) {
      if (event == PopupMenuController._eventHide) {
        _hideOverlay();
      }
      if (event == PopupMenuController._eventShow) {
        _showOverlay();
      }
    };

    ///add listener after paint to avoid bugs
    WidgetsBinding.instance.addPostFrameCallback((data) {
      if (mounted) {
        _menuController?.addListener(_listener);
        if (_menuController?._isShowPop ?? false) {
          _showOverlay();
        }
      }
    });
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
  void dispose() {
    _menuController?.removeListener(_listener);

    ///remove overlay
    _currentShowOverlay?.remove();
    _currentShowOverlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _currentKey,
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.triggerType == PopupMenuTriggerType.onLongPress
          ? () {
              _menuController?.show();
            }
          : null,
      onTap: widget.triggerType == PopupMenuTriggerType.onTap
          ? () {
              _menuController?.show();
            }
          : null,
      child: _buildChild(),
    );
  }

  ///build child
  Widget _buildChild() {
    if (widget.showChildTop && _currentIsPop) {
      return SizedBox(
        width: _currentRect.width,
        height: _currentRect.height,
      );
    } else {
      return widget.child;
    }
  }

  ///show overlay
  void _showOverlay() {
    ///if overlay is not show ,show overlay
    if (_currentShowOverlay == null) {
      ///get child size and location
      RenderBox renderBox =
          _currentKey.currentContext?.findRenderObject() as RenderBox;
      final Offset offset = renderBox.localToGlobal(Offset.zero);
      _currentRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        renderBox.size.width,
        renderBox.size.height,
      );

      ///current is pop
      _currentIsPop = true;
      if (mounted) {
        setState(() {});
      }

      ///show overlay later
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
      _animationHoverController.show();
    }
  }

  ///hide overlay
  void _hideOverlay() {
    _animationController.hide();
    _animationHoverController.hide();
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
              if (widget.barrierDismissible) {
                _hideOverlay();
              }
            },
            child: _buildContent(),
          );
  }

  ///build content
  Widget _buildContent() {
    ///offset
    final Rect rect = _currentRect;

    ///build menus
    List<Widget> menusWidgets = widget.menusBuilder(context, _menuController!);

    ///menus
    List<Widget> menus =
        createListWithSeparators(menusWidgets, _buildDivider());

    ///width and height
    double menuWidth = widget.menuWidth;
    double menuHeight =
        (widget.menuHeight + _getDividerHeight()) * menusWidgets.length +
            (widget.subHeadHeight ?? 0);

    ///get the container rect
    Rect bigRect = Rect.fromLTWH(
      widget.contentPadding.left,
      widget.contentPadding.top,
      MediaQuery.of(context).size.width -
          widget.contentPadding.left -
          widget.contentPadding.right,
      MediaQuery.of(context).size.height -
          widget.contentPadding.top -
          widget.contentPadding.bottom,
    );

    ///limit the rect
    Rect smallRect = Rect.fromLTWH(
      0,
      0,
      menuWidth,
      menuHeight,
    );

    ///check which space is larger
    bool showDown = (bigRect.height - rect.top - smallRect.height) >= rect.top;

    ///position
    Offset pos;

    ///get left and top
    if (showDown) {
      pos = Offset(
        rect.left - widget.menuWidth / 2 + rect.width / 2,
        rect.top + rect.height + 10,
      );
    } else {
      ///get left and top
      pos = Offset(
        rect.left - widget.menuWidth / 2 + rect.width / 2,
        rect.top - menuHeight - 10,
      );
    }

    ///pos limit
    Offset posLimit = constrainRectWithinRect(bigRect, smallRect, pos);

    ///delta offset
    double delta = ((pos.dx + widget.menuWidth / 2) - posLimit.dx);

    ///show or not
    bool visible = rect.left < MediaQuery.of(context).size.width &&
        rect.left + menuWidth > 0 &&
        rect.top < MediaQuery.of(context).size.height &&
        rect.top + menuHeight > 0 &&
        menus.isNotEmpty;

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,

      ///use stack for the popup
      child: Visibility(
        visible: visible,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildOverlayHover(),
            _buildOverlayChild(),

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
                  _currentIsPop = false;
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: _buildOverlayPopContent(showDown, delta, menus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///hover
  Widget _buildOverlayHover() {
    return PopupAnimation(
      controller: _animationHoverController,
      child: widget.hover ?? const SizedBox(),
    );
  }

  ///show child or not
  Widget _buildOverlayChild() {
    if (widget.showChildTop) {
      return Container(
        margin: EdgeInsets.fromLTRB(_currentRect.left, _currentRect.top, 0, 0),
        width: _currentRect.width,
        height: _currentRect.height,
        child: widget.child,
      );
    } else {
      return const SizedBox();
    }
  }

  ///menus
  Widget _buildOverlayPopContent(
      bool showDown, double delta, List<Widget> menus) {
    ///content
    Widget contentWidget = BubbleContainer(
      width: widget.menuWidth,
      shadowColor: widget.shadowColor,
      shadowElevation: widget.shadowElevation,
      shadowOccluder: widget.shadowOccluder,
      type: showDown ? BubbleType.top : BubbleType.bottom,
      radius: widget.radius,
      deltaOffset: delta,
      color: widget.backgroundColor,
      child: Column(
        verticalDirection:
            showDown ? VerticalDirection.down : VerticalDirection.up,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: menus,
      ),
    );

    ///sub head
    if (widget.subHead == null) {
      return contentWidget;
    } else {
      return showDown
          ? Column(
              children: [
                widget.subHead!,
                contentWidget,
              ],
            )
          : Column(
              children: [
                contentWidget,
                widget.subHead!,
              ],
            );
    }
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
