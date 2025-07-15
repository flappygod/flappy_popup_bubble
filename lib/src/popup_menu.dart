import 'package:flutter/material.dart';
import 'bubble_container.dart';
import 'popup_animation.dart';
import 'bubble_painter.dart';
import 'dart:math';

///type
enum PopupMenuTriggerType {
  none,
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

///build menu
typedef PopupMenuBuilder = List<Widget> Function(
  BuildContext context,
  PopupMenuController controller,
);

///build sub head
typedef PopupSubHeadBuilder = Widget Function(
  BuildContext context,
  PopupMenuController controller,
);

///overlay child builder
typedef PopupSubOverlayProxyChildBuilder = Widget Function(
  Widget child,
  Rect childRect,
  bool showDown,
);

///pop feed animation alpha controller
class PopupMenuController {
  static const int _eventShow = 1;
  static const int _eventHide = 2;
  static const int _eventRebuild = 3;

  ///listeners
  final Set<ValueChanged<int>> _listeners = {};

  ///is show pop
  bool _isShowPop = false;

  bool isShow() {
    return _isShowPop;
  }

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
  final PopupSubOverlayProxyChildBuilder? subOverlayChildProxyBuilder;
  final PopupMenuSubHeadAlign subHeadAlign;

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
    this.subHeadAlign = PopupMenuSubHeadAlign.start,
    this.subOverlayChildProxyBuilder,
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
  final GlobalKey _currentChildKey = GlobalKey();
  Rect _currentChildRect = Rect.zero;
  bool _currentIsPop = false;

  ///menu
  final GlobalKey _popupMenuKey = GlobalKey();
  Rect? _currentPopupRect;

  ///children
  List<Widget>? _cacheMenus;
  Widget? _cacheSubHead;

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
        ///清空
        _cacheMenus = null;
        _cacheSubHead = null;

        ///计算大小
        _measurePopupMenuSize();

        ///需要重构
        _currentShowOverlay?.markNeedsBuild();
      }
    };

    _checkNeedShowOrNot();
    super.initState();
  }

  ///check and show popup menu
  void _measurePopupMenuSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ///如果rect已经存在了，已经拿到了
      RenderBox? renderBox =
          _popupMenuKey.currentContext?.findRenderObject() as RenderBox?;
      final Offset offset =
          renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
      Rect newRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        renderBox?.size.width ?? 0,
        renderBox?.size.height ?? 0,
      );

      ///不相等进行刷新
      if (_currentPopupRect == null || !newRect.overlaps(_currentPopupRect!)) {
        _currentPopupRect = newRect;
        _currentShowOverlay?.markNeedsBuild();
      }
    });
  }

  ///check need show or not
  void _checkNeedShowOrNot() {
    WidgetsBinding.instance.addPostFrameCallback((data) {
      if (mounted) {
        _menuController?.addListener(_listener);
        if (_menuController?._isShowPop ?? false) {
          _showOverlay();
        }
      }
    });
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
      key: _currentChildKey,
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
        width: _currentChildRect.width,
        height: _currentChildRect.height,
      );
    } else {
      return widget.child;
    }
  }

  ///show overlay
  void _showOverlay() {
    ///is already show
    if (_currentShowOverlay != null) {
      return;
    }

    ///show call back
    if (widget.onPopupShow != null) {
      widget.onPopupShow!();
    }

    ///get child size and location
    RenderBox renderBox =
        _currentChildKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    _currentChildRect = Rect.fromLTWH(
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

    ///计算高度
    _measurePopupMenuSize();
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

  ///build Separators
  List<Widget> createListWithSeparators(List<Widget> originalList) {
    List<Widget> listWithSeparators = [];
    for (int i = 0; i < originalList.length; i++) {
      if (i == originalList.length - 1) {
        listWithSeparators.add(originalList[i]);
      } else {
        listWithSeparators.add(
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.dividerColor,
                  width: _getDividerHeight(),
                ),
              ),
            ),
            child: originalList[i],
          ),
        );
      }
    }
    return listWithSeparators;
  }

  ///build pop up member
  Widget _buildPopUpMenu() {
    ///穿透
    if (widget.translucent) {
      return _buildContent();
    }

    ///不穿透的情况增加点击事件
    return GestureDetector(
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
    _cacheMenus ??= widget.menusBuilder(context, _menuController!);

    ///sub head option
    _cacheSubHead ??= (widget.subHeadBuilder != null)
        ? widget.subHeadBuilder!(context, _menuController!)
        : null;

    ///offset
    final Rect rect = _currentChildRect;

    ///width and height
    double menuWidth = _currentPopupRect?.width ?? 0;
    double menuHeight = _currentPopupRect?.height ?? 0;

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
    double delta = ((pos.dx + menuWidth / 2) - posLimit.dx);

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildOverlayHover(),
          _buildOverlayChild(
            Offset(showPosX, showPosY),
            showDown,
          ),
          _buildOverLayPop(
            Offset(showPosX, showPosY),
            showDown,
            delta,
            _cacheMenus ?? [],
            _cacheSubHead,
          )
        ],
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
  Widget _buildOverlayChild(Offset menuOffset, bool showDown) {
    if (widget.showChildTop) {
      ///rebuild child if need
      Widget child = widget.subOverlayChildProxyBuilder != null
          ? widget.subOverlayChildProxyBuilder!(
              widget.child,
              _currentChildRect,
              showDown,
            )
          : widget.child;

      ///check to show child
      double top = showDown
          ? min(_currentChildRect.top,
              menuOffset.dy - _currentChildRect.height - widget.offsetSpace)
          : max(
              _currentChildRect.top,
              menuOffset.dy +
                  (_currentPopupRect?.height ?? 0) +
                  widget.offsetSpace);

      return Positioned(
        left: _currentChildRect.left,
        top: top,
        child: SizedBox(
          width: _currentChildRect.width,
          height: _currentChildRect.height,
          child: IgnorePointer(
            child: HeroMode(
              enabled: false,
              child: child,
            ),
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
    List<Widget> menus,
    Widget? header,
  ) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: PopupAnimation(
        controller: _animationController,
        onHide: () {
          _currentShowOverlay?.remove();
          _currentShowOverlay = null;
          widget.controller?._isShowPop = false;
          _currentIsPop = false;
          _currentPopupRect = null;
          _cacheMenus = null;
          _cacheSubHead = null;
          if (mounted) {
            setState(() {});
          }
          if (widget.onPopupHide != null) {
            widget.onPopupHide!();
          }
        },
        child: SizedBox(
          key: _popupMenuKey,
          child: Visibility(
            visible: _currentPopupRect != null,
            maintainState: true,
            maintainSize: true,
            maintainAnimation: true,
            maintainSemantics: true,
            child: _buildOverlayPopContent(
              showDown,
              delta,
              menus,
              header,
            ),
          ),
        ),
      ),
    );
  }

  ///menus
  Widget _buildOverlayPopContent(
    bool showDown,
    double delta,
    List<Widget> menus,
    Widget? subHead,
  ) {
    ///bubble
    Widget content;
    if (widget.bubbleDecoration != null) {
      content = Container(
        decoration: widget.bubbleDecoration,
        child: Column(
          verticalDirection: VerticalDirection.down,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: createListWithSeparators(menus),
        ),
      );
    } else {
      content = BubbleContainer(
        type: showDown ? BubbleType.top : BubbleType.bottom,
        deltaOffset: delta,
        radius: widget.bubbleOptions.bubbleRadius,
        color: widget.bubbleOptions.bubbleColor,
        shadowColor: widget.bubbleOptions.bubbleShadowColor,
        shadowElevation: widget.bubbleOptions.bubbleShadowElevation,
        shadowOccluder: widget.bubbleOptions.bubbleShadowOccluder,
        child: Column(
          verticalDirection: VerticalDirection.down,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: createListWithSeparators(menus),
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
      crossAxisAlignment: widget.subHeadAlign == PopupMenuSubHeadAlign.start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        subHead,
        content,
      ],
    );
  }

  /// Build constrain rect
  Offset constrainRectWithinRect(
      Rect bigRect, Rect smallRect, Offset smallRectOffset) {
    // 计算小 Rect 右下角的 Offset
    Offset smallRectBottomRight =
        smallRectOffset + Offset(smallRect.width, smallRect.height);

    // 计算小 Rect 能够移动的最大 Offset
    double maxDx = bigRect.right - smallRect.width;
    double maxDy = bigRect.bottom - smallRect.height;

    // 确保 clamp 的参数顺序正确
    double minDx = bigRect.left;
    double minDy = bigRect.top;

    // 如果 min > max，调整为合理的范围
    if (minDx > maxDx) {
      maxDx = minDx;
    }
    if (minDy > maxDy) {
      maxDy = minDy;
    }

    // 确保小 Rect 的左上角 Offset 不会超出大 Rect 的边界
    double newDx = smallRectOffset.dx.clamp(minDx, maxDx);
    double newDy = smallRectOffset.dy.clamp(minDy, maxDy);

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
