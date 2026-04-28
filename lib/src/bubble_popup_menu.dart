import 'package:flutter/material.dart';
import 'bubble_container.dart';
import 'bubble_popup_animation.dart';
import 'bubble_painter.dart';
import 'dart:math';

///type
enum BubblePopupMenuTriggerType {
  none,
  onTap,
  onLongPress,
}

///sub head align
enum BubblePopupMenuSubHeadAlign {
  start,
  center,
  end,
}

///sub head align
enum BubblePopupMenuAlign {
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

  const PopupBubbleOptions({
    this.bubbleColor = Colors.white,
    this.bubbleRadius = const BorderRadius.all(Radius.circular(8)),
    this.bubbleShadowColor = Colors.black38,
    this.bubbleShadowElevation = 5.0,
  });
}

///popup menu background
class PopupMenuBackground {
  final PopupBubbleOptions? bubbleOptions;
  final Decoration? decoration;

  const PopupMenuBackground.bubble({
    PopupBubbleOptions options = const PopupBubbleOptions(),
  })  : bubbleOptions = options,
        decoration = null;

  const PopupMenuBackground.decoration(
    Decoration this.decoration,
  ) : bubbleOptions = null;
}

///build menu
typedef BubblePopupMenuBuilder = List<Widget> Function(
  BuildContext context,
  BubblePopupMenuController controller,
);

///build sub head
typedef PopupMenuSubHeadBuilder = Widget Function(
  BuildContext context,
  BubblePopupMenuController controller,
);

///overlay child builder
typedef PopupSubOverlayProxyChildBuilder = Widget Function(
  Widget child,
  Rect childRect,
  bool showDown,
);

///pop feed animation alpha controller
class BubblePopupMenuController {
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
    for (final ValueChanged<int> item in _listeners.toList()) {
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
class BubblePopupMenu extends StatefulWidget {
  ///controller
  final BubblePopupMenuController? controller;

  ///menus
  final BubblePopupMenuBuilder menusBuilder;

  ///sub head
  final PopupMenuSubHeadBuilder? subHeadBuilder;
  final PopupSubOverlayProxyChildBuilder? subOverlayChildProxyBuilder;
  final BubblePopupMenuSubHeadAlign subHeadAlign;

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
  final BubblePopupMenuTriggerType triggerType;

  ///padding used to keep popup within the overlay boundary
  final EdgeInsets boundaryPadding;

  ///popup content bubble padding
  final EdgeInsets bubblePadding;

  ///touch to close
  final bool barrierDismissible;

  ///hover widget
  final Widget? hover;

  ///align
  final BubblePopupMenuAlign align;

  ///background
  final PopupMenuBackground background;

  /// enable anim scale
  final bool bubbleAnimScaleEnable;

  /// anim curve
  final Curve bubbleAnimCurve;

  /// anim duration
  final Duration bubbleAnimDuration;

  ///show
  final VoidCallback? onPopupShow;

  ///hide
  final VoidCallback? onPopupHide;

  const BubblePopupMenu({
    super.key,
    this.controller,
    required this.child,
    required this.menusBuilder,
    this.dividerColor = Colors.black87,
    this.triggerType = BubblePopupMenuTriggerType.onLongPress,
    this.barrierDismissible = true,
    this.showChildTop = false,
    this.translucent = false,
    this.offsetDx,
    this.offsetDy,
    this.offsetSpace = 10,
    this.boundaryPadding = EdgeInsets.zero,
    this.bubblePadding = EdgeInsets.zero,
    this.hover,
    this.subHeadBuilder,
    this.subHeadAlign = BubblePopupMenuSubHeadAlign.start,
    this.subOverlayChildProxyBuilder,
    this.align = BubblePopupMenuAlign.center,
    this.bubbleAnimScaleEnable = true,
    this.bubbleAnimCurve = Curves.linear,
    this.bubbleAnimDuration = const Duration(milliseconds: 240),
    this.background = const PopupMenuBackground.bubble(),
    this.onPopupShow,
    this.onPopupHide,
  }) : assert(
          !translucent || !barrierDismissible,
          'When translucent is true, barrierDismissible must be false.',
        );

  @override
  State<StatefulWidget> createState() {
    return _BubblePopupMenuState();
  }
}

class _BubblePopupMenuState extends State<BubblePopupMenu> {
  ///menu controller
  BubblePopupMenuController? _menuController;

  ///listener
  late ValueChanged<int> _listener;

  ///controller
  final BubblePopupAnimationController _animationController =
      BubblePopupAnimationController();

  ///controller
  final BubblePopupAnimationController _animationHoverController =
      BubblePopupAnimationController();

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
    _menuController = widget.controller ?? BubblePopupMenuController();

    ///add listener
    _listener = (event) {
      if (event == BubblePopupMenuController._eventHide) {
        _hideOverlay();
      }
      if (event == BubblePopupMenuController._eventShow) {
        _showOverlay();
      }
      if (event == BubblePopupMenuController._eventRebuild) {
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
      if (_currentPopupRect == null || newRect != _currentPopupRect) {
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
  void didUpdateWidget(BubblePopupMenu oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _menuController?.removeListener(_listener);
      _menuController = widget.controller ?? BubblePopupMenuController();
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
      onLongPress: widget.triggerType == BubblePopupMenuTriggerType.onLongPress
          ? () {
              _menuController?.show();
            }
          : null,
      onTap: widget.triggerType == BubblePopupMenuTriggerType.onTap
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

    ///get child size and location
    final Object? renderObject =
        _currentChildKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }
    final RenderBox renderBox = renderObject;
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
    if (widget.onPopupShow != null) {
      widget.onPopupShow!();
    }
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
      widget.boundaryPadding.left,
      widget.boundaryPadding.top,
      MediaQuery.of(context).size.width -
          widget.boundaryPadding.left -
          widget.boundaryPadding.right,
      MediaQuery.of(context).size.height -
          widget.boundaryPadding.top -
          widget.boundaryPadding.bottom,
    );

    ///limit the rect
    Rect menuRect = Rect.fromLTWH(
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
      double left;
      switch (widget.align) {
        case BubblePopupMenuAlign.center:
          left = rect.left - menuWidth / 2 + rect.width / 2;
          break;
        case BubblePopupMenuAlign.start:
          left = rect.left;
          break;
        case BubblePopupMenuAlign.end:
          left = rect.right - menuWidth;
          break;
      }
      pos = Offset(
        left,
        rect.top + rect.height + widget.offsetSpace,
      );
    } else {
      double left;
      switch (widget.align) {
        case BubblePopupMenuAlign.center:
          left = rect.left - menuWidth / 2 + rect.width / 2;
          break;
        case BubblePopupMenuAlign.start:
          left = rect.left;
          break;
        case BubblePopupMenuAlign.end:
          left = rect.right - menuWidth;
          break;
      }
      pos = Offset(
        left,
        rect.top - menuHeight - widget.offsetSpace,
      );
    }

    ///pos limit
    Offset posLimit = constrainRectWithinRect(bigRect, menuRect, pos);

    double delta;

    ///delta offset
    switch (widget.align) {
      case BubblePopupMenuAlign.start:
        delta = (rect.width / 2) + (pos.dx - posLimit.dx);
        break;
      case BubblePopupMenuAlign.end:
        delta = (menuWidth - rect.width / 2) + (pos.dx - posLimit.dx);
        break;
      case BubblePopupMenuAlign.center:
        delta = (menuWidth / 2) + (pos.dx - posLimit.dx);
        break;
    }

    double showPosY = posLimit.dy - (widget.offsetDy ?? 0);
    double showPosX = posLimit.dx + (widget.offsetDx ?? 0);

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
    if (widget.hover == null) {
      return const SizedBox.shrink();
    }
    return BubblePopupAnimation(
      controller: _animationHoverController,
      duration: widget.bubbleAnimDuration,
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
    Alignment align;
    switch (widget.align) {
      case BubblePopupMenuAlign.start:
        if (showDown) {
          align = Alignment.topLeft;
        } else {
          align = Alignment.bottomLeft;
        }
        break;
      case BubblePopupMenuAlign.end:
        if (showDown) {
          align = Alignment.topRight;
        } else {
          align = Alignment.bottomRight;
        }
        break;
      case BubblePopupMenuAlign.center:
        if (showDown) {
          align = Alignment.topCenter;
        } else {
          align = Alignment.bottomCenter;
        }
        break;
    }
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: BubblePopupAnimation(
        controller: _animationController,
        enableScale: widget.bubbleAnimScaleEnable,
        curve: widget.bubbleAnimCurve,
        reverseCurve: widget.bubbleAnimCurve,
        duration: widget.bubbleAnimDuration,
        scaleAlignment: align,
        onHide: () {
          _currentShowOverlay?.remove();
          _currentShowOverlay = null;
          _menuController?._isShowPop = false;
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
    final PopupBubbleOptions bubbleOptions =
        widget.background.bubbleOptions ?? const PopupBubbleOptions();
    if (widget.background.decoration != null) {
      content = Container(
        decoration: widget.background.decoration,
        child: Padding(
          padding: widget.bubblePadding,
          child: Column(
            verticalDirection: VerticalDirection.down,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: createListWithSeparators(menus),
          ),
        ),
      );
    } else {
      content = BubbleContainer(
        type: showDown ? BubbleType.top : BubbleType.bottom,
        deltaOffset: delta,
        radius: bubbleOptions.bubbleRadius,
        color: bubbleOptions.bubbleColor,
        shadowColor: bubbleOptions.bubbleShadowColor,
        shadowElevation: bubbleOptions.bubbleShadowElevation,
        child: Padding(
          padding: widget.bubblePadding,
          child: Column(
            verticalDirection: VerticalDirection.down,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: createListWithSeparators(menus),
          ),
        ),
      );
    }

    /// sub head is null
    if (subHead == null) {
      return content;
    }

    /// 布局处理
    CrossAxisAlignment alignment;
    switch (widget.subHeadAlign) {
      case BubblePopupMenuSubHeadAlign.start:
        alignment = CrossAxisAlignment.start;
        break;
      case BubblePopupMenuSubHeadAlign.end:
        alignment = CrossAxisAlignment.end;
        break;
      case BubblePopupMenuSubHeadAlign.center:
        alignment = CrossAxisAlignment.center;
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection:
          showDown ? VerticalDirection.down : VerticalDirection.up,
      crossAxisAlignment: alignment,
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
