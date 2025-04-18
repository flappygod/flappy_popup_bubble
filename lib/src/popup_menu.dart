import 'package:flutter/material.dart';
import 'bubble_container.dart';
import 'popup_animation.dart';
import 'bubble_painter.dart';
import 'dart:math';

///type
enum PopupMenuTriggerType {
  onTap,
  onLongPress,
}

///sub head align
enum PopupMenuSubHeadAlign {
  start,
  end,
}

///sub head align
enum PopupMenuAlign {
  start,
  center,
  end,
}

///bubble options
class PopupBubbleOptions {
  final Color bubbleColor;
  final BorderRadius bubbleRadius;
  final Color? bubbleShadowColor;
  final double bubbleShadowElevation;
  final bool bubbleShadowOccluder;

  const PopupBubbleOptions({
    this.bubbleColor = const Color(0xFF5A5B5E),
    this.bubbleRadius = const BorderRadius.all(Radius.circular(8)),
    this.bubbleShadowColor,
    this.bubbleShadowElevation = 5.0,
    this.bubbleShadowOccluder = true,
  });
}

///sub head options
class PopupMenuWithOptions {
  double itemHeight;
  double itemWidth;
  List<Widget> children;

  PopupMenuWithOptions({
    this.itemWidth = 120,
    this.itemHeight = 40,
    required this.children,
  });
}

///sub head options
class PopupSubHeadWithOptions {
  double height;
  double width;
  PopupMenuSubHeadAlign align;
  Widget child;

  PopupSubHeadWithOptions({
    this.align = PopupMenuSubHeadAlign.end,
    required this.height,
    required this.child,
    required this.width,
  });
}

///build menu
typedef PopupMenuBuilder = PopupMenuWithOptions Function(
  BuildContext context,
  PopupMenuController controller,
);

///build sub head
typedef PopupSubHeadBuilder = PopupSubHeadWithOptions Function(
  BuildContext context,
  PopupMenuController controller,
);

///pop feed animation alpha controller
class PopupMenuController {
  static const int _eventShow = 1;
  static const int _eventHide = 2;
  static const int _eventRebuild = 3;

  ///listeners
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

  ///rebuild items and subviews
  void rebuild() {
    notifyListeners(_eventRebuild);
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

  ///menus
  final PopupMenuBuilder menusBuilder;

  ///sub head
  final PopupSubHeadBuilder? subHeadBuilder;

  ///divider
  final Color dividerColor;

  ///child widget
  final Widget child;

  final double? offsetDx;
  final double? offsetDy;

  final double offsetSpace;

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

  ///hover widget
  final Widget? hover;

  ///align
  final PopupMenuAlign align;

  ///bubble Decoration
  final Decoration? bubbleDecoration;

  ///bubble options
  final PopupBubbleOptions bubbleOptions;

  ///show
  final VoidCallback? onPopupShow;

  ///hide
  final VoidCallback? onPopupHide;

  const PopupMenu({
    super.key,
    this.controller,
    required this.child,
    required this.menusBuilder,
    this.dividerColor = Colors.black87,
    this.triggerType = PopupMenuTriggerType.onLongPress,
    this.barrierDismissible = true,
    this.showChildTop = false,
    this.translucent = false,
    this.offsetDx,
    this.offsetDy,
    this.offsetSpace = 10,
    this.contentPadding = EdgeInsets.zero,
    this.hover,
    this.subHeadBuilder,
    this.align = PopupMenuAlign.center,
    this.bubbleOptions = const PopupBubbleOptions(),
    this.bubbleDecoration,
    this.onPopupShow,
    this.onPopupHide,
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
      if (event == PopupMenuController._eventRebuild) {
        _currentShowOverlay?.markNeedsBuild();
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
      if (widget.onPopupShow != null) {
        widget.onPopupShow!();
      }

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
    ///build menus
    PopupMenuWithOptions menus = widget.menusBuilder(context, _menuController!);

    ///sub head option
    PopupSubHeadWithOptions? header;
    if (widget.subHeadBuilder != null) {
      header = widget.subHeadBuilder!(context, _menuController!);
    }

    ///offset
    final Rect rect = _currentRect;

    ///width and height
    double menuWidth = max(menus.itemWidth, header?.width ?? 0);
    double menuHeight =
        (menus.itemHeight + _getDividerHeight()) * menus.children.length +
            (header?.height ?? 0);

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
    bool showDown =
        (bigRect.bottom - rect.top - rect.height) >= (rect.top - bigRect.top);

    ///position
    Offset pos;

    ///get left and top
    if (showDown) {
      pos = Offset(
        rect.left - menuWidth / 2 + rect.width / 2,
        rect.top + rect.height + widget.offsetSpace,
      );
    } else {
      ///get left and top
      pos = Offset(
        rect.left - menuWidth / 2 + rect.width / 2,
        rect.top - menuHeight - widget.offsetSpace,
      );
    }

    ///pos limit
    Offset posLimit = constrainRectWithinRect(bigRect, smallRect, pos);

    ///delta offset
    double delta = ((pos.dx + menus.itemWidth / 2) - posLimit.dx);

    ///show or not
    bool visible = rect.left < MediaQuery.of(context).size.width &&
        rect.left + menuWidth > 0 &&
        rect.top < MediaQuery.of(context).size.height &&
        rect.top + menuHeight > 0;

    double showPosY = posLimit.dy - (widget.offsetDy ?? 0);
    double showPosX = 0;

    ///align
    switch (widget.align) {
      case PopupMenuAlign.start:
        showPosX = rect.left;
        break;
      case PopupMenuAlign.end:
        showPosX = rect.right - menuWidth;
        break;
      case PopupMenuAlign.center:
        showPosX = posLimit.dx - (widget.offsetDx ?? 0);
        break;
    }

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
            _buildOverLayPop(
              Offset(
                showPosX,
                showPosY,
              ),
              showDown,
              delta,
              menus,
              header,
            )
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
      return Positioned(
        left: _currentRect.left,
        top: _currentRect.top,
        child: SizedBox(
          width: _currentRect.width,
          height: _currentRect.height,
          child: IgnorePointer(
            child: widget.child,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  ///build overlay pop
  Widget _buildOverLayPop(
    Offset offset,
    bool showDown,
    double delta,
    PopupMenuWithOptions menus,
    PopupSubHeadWithOptions? header,
  ) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: PopupAnimation(
        controller: _animationController,
        onHide: () {
          _currentShowOverlay?.remove();
          _currentShowOverlay = null;
          _currentIsPop = false;
          if (mounted) {
            setState(() {});
          }
          if (widget.onPopupHide != null) {
            widget.onPopupHide!();
          }
        },
        child: _buildOverlayPopContent(
          showDown,
          delta,
          menus,
          header,
        ),
      ),
    );
  }

  ///menus
  Widget _buildOverlayPopContent(bool showDown, double delta,
      PopupMenuWithOptions menus, PopupSubHeadWithOptions? subHead) {
    ///bubble
    Widget content;
    if (widget.bubbleDecoration != null) {
      content = Container(
        width: menus.itemWidth,
        decoration: widget.bubbleDecoration,
        child: Column(
          verticalDirection:
              showDown ? VerticalDirection.down : VerticalDirection.up,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: createListWithSeparators(menus.children, _buildDivider()),
        ),
      );
    } else {
      content = BubbleContainer(
        type: showDown ? BubbleType.top : BubbleType.bottom,
        width: menus.itemWidth,
        deltaOffset: delta,
        radius: widget.bubbleOptions.bubbleRadius,
        color: widget.bubbleOptions.bubbleColor,
        shadowColor: widget.bubbleOptions.bubbleShadowColor,
        shadowElevation: widget.bubbleOptions.bubbleShadowElevation,
        shadowOccluder: widget.bubbleOptions.bubbleShadowOccluder,
        child: Column(
          verticalDirection:
              showDown ? VerticalDirection.down : VerticalDirection.up,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: createListWithSeparators(menus.children, _buildDivider()),
        ),
      );
    }

    ///sub head is null
    if (subHead == null) {
      return content;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection:
          showDown ? VerticalDirection.down : VerticalDirection.up,
      crossAxisAlignment: subHead.align == PopupMenuSubHeadAlign.start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: subHead.width,
          height: subHead.height,
          child: subHead.child,
        ),
        content,
      ],
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
