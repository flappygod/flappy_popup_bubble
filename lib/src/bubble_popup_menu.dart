import 'package:flutter/material.dart';
import 'bubble_popup_animation.dart';
import 'bubble_popup_archor.dart';
import 'bubble_dialog_frame.dart';
import 'bubble_container.dart';
import 'bubble_painter.dart';
import 'dart:math';

///弹窗漂浮的类型
enum BubblePopupMenuType {
  //layer
  layer,
  //dialog
  dialog,
}

/// trigger type
/// 触发类型
enum BubblePopupMenuTriggerType {
  none,
  onTap,
  onLongPress,
}

/// sub head align
/// 子视图对齐方式
enum BubblePopupMenuAlign {
  start,
  center,
  end,
}

/// popup direction
/// 弹出方向
enum BubblePopupMenuDirection {
  auto,
  up,
  down,
}

/// popup content layout mode
/// 弹层内容布局模式
enum BubblePopupMenuLayoutMode {
  /// 可滚动：沿用原有 Column + 位移 + 滚动逻辑
  scroll,

  /// 可轻微回弹滚动：沿用 scroll 模式的布局和动画；
  /// 总高度超过可视区时，将操作菜单向 child 方向平移并叠在其上方；
  /// 滚动上限按 menu translate 后的真实视觉边界计算，避免高 child 滚动不全或滚动过量。
  overlay,
}

/// bubble options
/// 气泡样式配置
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

/// popup menu background
/// 弹窗背景配置
class PopupMenuBackground {
  final PopupBubbleOptions? bubbleOptions;
  final Decoration? decoration;

  const PopupMenuBackground.bubble({
    PopupBubbleOptions options = const PopupBubbleOptions(),
  })  : bubbleOptions = options,
        decoration = null;

  const PopupMenuBackground.decoration(this.decoration) : bubbleOptions = null;
}

/// build menu
/// 构建菜单列表
typedef BubblePopupMenuBuilder<T> = List<Widget> Function(
  BuildContext context,
  BubblePopupMenuController<T> controller,
  T? data,
);

/// build header
/// 构建头部
typedef BubblePopupMenuHeaderBuilder<T> = Widget Function(
  BuildContext context,
  BubblePopupMenuController<T> controller,
  T? data,
);

/// build child
/// 构建 child
typedef BubblePopupMenuChildBuilder<T> = Widget Function(
  BuildContext context,
  BubblePopupMenuController<T> controller,
  T? data,
);

/// pop feed animation alpha controller
/// 弹窗控制器
class BubblePopupMenuController<T> {
  static const int _eventShow = 1;
  static const int _eventHide = 2;
  static const int _eventRebuild = 3;

  /// listeners
  /// 监听器集合
  final Set<ValueChanged<int>> _listeners = {};

  /// is show pop
  /// 当前是否显示弹窗
  bool _currentIsShow = false;

  /// popup data
  /// 当前弹窗携带的数据
  T? _currentData;

  /// hide with animation
  /// 隐藏时是否播放退出动画
  bool _hideAnimated = true;

  /// current popup data
  /// 当前弹窗数据
  T? get data => _currentData;

  /// whether popup is showing
  /// 是否正在显示弹窗
  bool isShow() {
    return _currentIsShow;
  }

  /// show menu
  /// 显示菜单，可选传入数据
  void show({T? data}) {
    _currentData = data;
    _currentIsShow = true;
    notifyListeners(_eventShow);
  }

  /// hide menu
  /// 隐藏菜单，可指定是否播放退出动画
  void hide({bool animated = true}) {
    _hideAnimated = animated;
    _currentIsShow = false;
    notifyListeners(_eventHide);
  }

  /// rebuild items and subviews
  /// 刷新菜单和子视图
  void rebuild() {
    notifyListeners(_eventRebuild);
  }

  /// clear data
  /// 清空当前数据
  void _clearData() {
    _currentData = null;
  }

  /// notify listener
  /// 通知监听器
  void notifyListeners(int data) {
    for (final ValueChanged<int> item in _listeners.toList()) {
      item(data);
    }
  }

  /// add listener
  /// 添加监听器
  void addListener(ValueChanged<int> listener) {
    _listeners.add(listener);
  }

  /// remove listener
  /// 移除监听器
  void removeListener(ValueChanged<int> listener) {
    _listeners.remove(listener);
  }
}

/// add popup menu
/// 气泡弹窗菜单
class BubblePopupMenu<T> extends StatefulWidget {
  /// controller
  /// 控制器
  final BubblePopupMenuController<T>? controller;

  /// 类型
  final BubblePopupMenuType type;

  /// header builder
  /// 头部构建器
  final BubblePopupMenuHeaderBuilder<T>? headerBuilder;

  /// child builder
  /// child 构建器
  final BubblePopupMenuChildBuilder<T>? childBuilder;

  /// menus builder
  /// 菜单构建器
  final BubblePopupMenuBuilder<T> menusBuilder;

  /// divider color
  /// 分割线颜色
  final Color dividerColor;

  /// child widget
  /// 触发弹窗的子组件
  final Widget? child;

  /// menu offset and space
  /// 菜单padding
  final EdgeInsets menuPadding;

  /// header space
  /// 头部Padding
  final EdgeInsets headerPadding;

  /// translucent
  /// 是否允许点击穿透
  final bool translucent;

  /// show child on top or not
  /// 弹窗显示时是否在原位置显示 child 占位/镜像
  final bool showChildTop;

  /// trigger type
  /// 触发方式
  final BubblePopupMenuTriggerType triggerType;

  /// padding used to keep popup within the overlay boundary
  /// 用于限制弹窗不超出边界的内边距
  final EdgeInsets boundaryPadding;

  /// popup content bubble padding
  /// 气泡内容内边距
  final EdgeInsets bubblePadding;

  /// touch to close
  /// 点击遮罩是否关闭
  final bool barrierDismissible;

  /// hover widget
  /// 悬浮层组件
  final Widget? hover;

  /// align
  /// 对齐方式
  final BubblePopupMenuAlign align;

  /// background
  /// 背景配置
  final PopupMenuBackground background;

  /// popup show direction
  /// 弹出方向
  final BubblePopupMenuDirection direction;

  /// content layout mode
  /// 内容布局模式
  final BubblePopupMenuLayoutMode layoutMode;

  /// Whether the header and menu fade out after overlay content scrolls more than 10 logical pixels.
  ///
  /// 仅在 [BubblePopupMenuLayoutMode.overlay] 下生效。滚动距离大于 10 时隐藏
  /// header 和 menu，回到 10 以内时重新展示。
  final bool autoHideEdgeItemsOnScroll;

  /// Whether to correct the maximum scroll extent using the translated visual boundary.
  ///
  /// 仅在 [BubblePopupMenuLayoutMode.overlay] 下生效。默认关闭，使用 Flutter
  /// 根据原始布局计算的最大滚动距离；开启后按 menu 平移后的视觉边界收紧滚动上限。
  final bool correctOverlayMaxScrollExtent;

  /// enable anim scale
  /// 是否启用缩放动画
  final bool bubbleAnimScaleEnable;

  /// anim duration
  /// 动画时长
  final Duration bubbleAnimDuration;

  /// anim curve
  /// 气泡动画曲线
  final Curve bubbleAnimCurve;

  /// anim curve
  /// 气泡动画曲线
  final Curve bubbleAnimReverseCurve;

  /// child curve
  /// child 平移动画曲线
  final Curve childTranslateCurve;

  /// child curve
  /// child 平移动画曲线
  final Curve childTranslateReverseCurve;

  /// show callback
  /// 显示回调
  final VoidCallback? onPopupShow;

  /// hide callback
  /// 隐藏回调
  final VoidCallback? onPopupHide;

  /// whether this menu instance should handle the current popup event
  /// 当前实例是否应处理弹窗事件（用于列表中共用 controller 的场景）
  final bool Function(T? data)? shouldHandlePopup;

  const BubblePopupMenu({
    super.key,
    this.controller,
    this.headerBuilder,
    this.childBuilder,
    this.type = BubblePopupMenuType.layer,
    this.child,
    required this.menusBuilder,
    this.dividerColor = Colors.transparent,
    this.triggerType = BubblePopupMenuTriggerType.onLongPress,
    this.barrierDismissible = true,
    this.showChildTop = false,
    this.translucent = false,
    this.menuPadding = const EdgeInsets.fromLTRB(0, 8, 0, 8),
    this.headerPadding = const EdgeInsets.fromLTRB(0, 8, 0, 8),
    this.boundaryPadding = EdgeInsets.zero,
    this.bubblePadding = EdgeInsets.zero,
    this.hover,
    this.align = BubblePopupMenuAlign.center,
    this.direction = BubblePopupMenuDirection.auto,
    this.layoutMode = BubblePopupMenuLayoutMode.scroll,
    this.autoHideEdgeItemsOnScroll = true,
    this.correctOverlayMaxScrollExtent = true,
    this.bubbleAnimScaleEnable = true,
    this.bubbleAnimDuration = const Duration(milliseconds: 320),
    this.bubbleAnimCurve = Curves.easeOutBack,
    this.bubbleAnimReverseCurve = Curves.easeOutBack,
    this.childTranslateCurve = Curves.easeOutBack,
    this.childTranslateReverseCurve = Curves.easeOutBack,
    this.background = const PopupMenuBackground.bubble(),
    this.onPopupShow,
    this.onPopupHide,
    this.shouldHandlePopup,
  })  : assert(child != null || childBuilder != null,
            'Either child or childBuilder must be provided.'),
        assert(
          !translucent || !barrierDismissible,
          'When translucent is true, barrierDismissible must be false.',
        );

  @override
  State<StatefulWidget> createState() => _BubblePopupMenuState<T>();
}

class _BubblePopupMenuState<T> extends State<BubblePopupMenu<T>>
    with SingleTickerProviderStateMixin {
  /// menu controller
  /// 菜单控制器
  late BubblePopupMenuController<T> _menuController;

  /// listener
  /// 事件监听器
  late ValueChanged<int> _listener;

  /// popup animation controller
  /// 弹窗动画控制器
  final BubblePopupAnimationController _animationController =
      BubblePopupAnimationController();

  /// hover animation controller
  /// 悬浮层动画控制器
  final BubblePopupAnimationController _animationHoverController =
      BubblePopupAnimationController();

  /// scroll controller
  /// 滚动控制器：
  /// 1. 监听滚动距离，控制 overlay 模式下 header / menu 的渐隐渐显；
  /// 2. 可根据 [BubblePopupMenu.correctOverlayMaxScrollExtent] 修正最大滚动距离。
  final _BubblePopupScrollController _scrollController =
      _BubblePopupScrollController();

  /// header / menu 自动隐藏的滚动阈值（逻辑像素）。
  static const double _edgeItemsHideScrollThreshold = 10;

  /// 当前是否展示滚动内容两端的 header 和 menu。
  ///
  /// 仅改变透明度和点击能力，不从布局树移除，避免滚动范围发生跳变。
  bool _showEdgeItems = true;

  /// 当前弹层内容是否正在拖动或惯性滚动。
  ///
  /// 滚动期间强制隐藏 header / menu，避免 offset 在阈值附近或回弹过程中
  /// 反复跨越 10px，导致边缘内容闪烁。
  bool _isPopupScrolling = false;

  /// translation controller
  /// 平移动画控制器
  late final AnimationController _translationController;
  late Animation<Offset> _translationAnimation;
  Offset _translationBeginOffset = Offset.zero;
  bool _translationHiding = false;

  /// 列表侧 anchor slot，用于读取 child 全局 rect（无需 GlobalKey）
  final BubblePopupAnchorScope _anchorScope = BubblePopupAnchorScope();

  /// child 的全局 key（showChildTop 时在列表与弹层之间 reparent）
  final GlobalKey _currentChildKey = GlobalKey();
  Rect _currentChildRect = Rect.zero;

  /// menu key
  /// menu 的全局 key
  final GlobalKey _popupMenuKey = GlobalKey();
  Rect? _currentPopupRect;

  /// header key
  /// header 的全局 key
  final GlobalKey _popupHeaderKey = GlobalKey();
  Rect? _currentHeaderRect;

  /// children cache
  /// 菜单缓存
  List<Widget>? _cacheMenus;

  /// overlay is show or not
  /// 当前 overlay
  OverlayEntry? _currentShowOverlay;

  /// 当前是否展示了dialog
  bool _isDialogShow = false;
  bool _isLayerShow = false;

  /// hide 收尾中，防止 removeRoute → whenComplete 重入 _onHideSuccess
  bool _isCleaningUp = false;

  /// showChildTop 时，[_currentChildKey] 当前是否挂在弹层侧。
  ///
  /// 生命周期：
  /// 1. show：置 true，child 从列表 reparent 到弹层
  /// 2. hide 收尾：先置 false 并刷新弹层，卸掉 HeroMode 下的 keyed child
  /// 3. 下一帧再 setState，把 key 归还给列表
  ///
  /// 避免关闭后立刻 push 其他 route（如 EmojiTraySheet）时出现 Duplicate GlobalKey。
  bool _popupOwnsChildKey = false;

  /// 当前展示的dialog
  final BubbleDialogFrameController _currentFrameController =
      BubbleDialogFrameController();

  /// 当前展示的dialogRoute
  BuildContext? _currentShowDialogContext;

  @override
  void initState() {
    super.initState();

    /// 直接监听内部 ScrollController，不依赖弹层由 dialog 还是 layer 承载；
    /// 是否真正启用自动隐藏由 layoutMode 和参数共同决定。
    _scrollController.addListener(_handlePopupScroll);

    ///位移动画初始化
    _translationController = AnimationController(
      vsync: this,
      duration: widget.bubbleAnimDuration,
    );
    _translationAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _translationController,
        curve: widget.childTranslateCurve,
        reverseCurve: widget.childTranslateReverseCurve,
      ),
    );

    ///设置监听
    _listener = (event) {
      ///隐藏弹出层
      if (event == BubblePopupMenuController._eventHide) {
        ///如果当前是弹出状态，执行隐藏操作
        if (_isLayerShow || _isDialogShow) {
          _hidePopUp(animated: _menuController._hideAnimated);
        }
      }

      ///展示弹出层
      if (event == BubblePopupMenuController._eventShow) {
        ///是否需要处理popUp
        final bool shouldHandle =
            widget.shouldHandlePopup?.call(_menuController.data) ?? true;
        if (!shouldHandle) {
          return;
        }

        ///可以展示，根据类型判断展示什么
        switch (widget.type) {
          case BubblePopupMenuType.dialog:
            _showDialog();
            break;
          case BubblePopupMenuType.layer:
            _showOverlay();
            break;
        }
      }

      ///执行界面刷新
      if (event == BubblePopupMenuController._eventRebuild) {
        ///清空menu缓存
        _cacheMenus = null;

        ///如果已经显示了，更新位置
        if (_isLayerShow || _isDialogShow) {
          _updateCurrentRect();
        }

        ///刷新界面
        _currentFrameController.refresh();

        ///添加post frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkPopupRelayout();
        });
      }
    };
    _menuController = widget.controller ?? BubblePopupMenuController<T>();
    _menuController.addListener(_listener);

    _checkNeedShowOrNot();
  }

  @override
  void didUpdateWidget(BubblePopupMenu<T> oldWidget) {
    ///更新控制器
    if (oldWidget.controller != widget.controller) {
      _menuController.removeListener(_listener);
      _menuController = widget.controller ?? BubblePopupMenuController<T>();
      _menuController.addListener(_listener);
    }

    ///更新动画
    if (oldWidget.bubbleAnimDuration != widget.bubbleAnimDuration) {
      _translationController.duration = widget.bubbleAnimDuration;
    }

    ///展示方式变化时先关闭当前弹层，避免 dialog / layer 状态并存
    if (oldWidget.type != widget.type && (_isLayerShow || _isDialogShow)) {
      _hidePopUp(animated: false);
    }

    /// 自动隐藏参数或布局模式变化时，立即同步 header / menu 状态。
    if (oldWidget.autoHideEdgeItemsOnScroll !=
            widget.autoHideEdgeItemsOnScroll ||
        oldWidget.layoutMode != widget.layoutMode) {
      _updateEdgeItemsVisibility();
    }

    /// 修正参数变化时刷新弹层，重新执行 ScrollPosition 的内容尺寸计算。
    if (oldWidget.correctOverlayMaxScrollExtent !=
            widget.correctOverlayMaxScrollExtent &&
        (_isLayerShow || _isDialogShow)) {
      _currentFrameController.refresh();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _menuController.removeListener(_listener);
    _cleanupPopupShell();
    _translationController.dispose();

    /// 先解除监听再释放 controller，避免销毁阶段继续刷新弹层。
    _scrollController.removeListener(_handlePopupScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 处理弹层内部滚动。
  ///
  /// 收起动画期间会主动回滚 scroll offset，此时不应让 header / menu
  /// 重新出现，否则退出动画过程中可能闪烁。
  void _handlePopupScroll() {
    if (_translationHiding) {
      return;
    }
    _updateEdgeItemsVisibility();
  }

  /// 根据当前滚动距离同步 header / menu 的可见状态。
  ///
  /// 仅在 overlay 模式且 [BubblePopupMenu.autoHideEdgeItemsOnScroll] 开启时生效；
  /// 滚动过程中始终隐藏；滚动结束后，offset 绝对值大于阈值时继续隐藏，
  /// 回到阈值内时展示。仅在可见状态改变时刷新，避免每个滚动帧都重建弹层。
  void _updateEdgeItemsVisibility() {
    final bool shouldAutoHide =
        widget.layoutMode == BubblePopupMenuLayoutMode.overlay &&
            widget.autoHideEdgeItemsOnScroll;
    final bool shouldShow = !shouldAutoHide ||
        (!_isPopupScrolling &&
            (!_scrollController.hasClients ||
                _scrollController.offset.abs() <=
                    _edgeItemsHideScrollThreshold));
    if (_showEdgeItems == shouldShow) {
      return;
    }
    _showEdgeItems = shouldShow;
    if (_isLayerShow || _isDialogShow) {
      _currentFrameController.refresh();
    }
  }

  /// 接收滚动生命周期通知，区分“正在滚动”和“滚动已经完全停止”。
  ///
  /// 使用 ScrollEndNotification 而不是手势抬起事件，因此惯性滚动和回弹阶段
  /// 也会持续保持隐藏，直到 ScrollPosition 真正稳定后才重新判断最终 offset。
  bool _handlePopupScrollNotification(ScrollNotification notification) {
    if (widget.layoutMode != BubblePopupMenuLayoutMode.overlay ||
        !widget.autoHideEdgeItemsOnScroll ||
        _translationHiding) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _isPopupScrolling = true;
      _updateEdgeItemsVisibility();
    } else if (notification is ScrollEndNotification) {
      _isPopupScrolling = false;
      _updateEdgeItemsVisibility();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ///child
    final Widget content = BubblePopupAnchor(
      scope: _anchorScope,
      child: _buildBaseChild(),
    );

    ///根据动作类型考虑是否增加
    ///GestureDetector
    switch (widget.triggerType) {
      case BubblePopupMenuTriggerType.none:
        return content;

      case BubblePopupMenuTriggerType.onLongPress:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            _menuController.show();
          },
          child: content,
        );

      case BubblePopupMenuTriggerType.onTap:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _menuController.show();
          },
          child: content,
        );
    }
  }

  /// build child
  /// 构建 child
  Widget _buildBaseChild() {
    if (widget.showChildTop && (_isLayerShow || _isDialogShow)) {
      return SizedBox(
        width: _currentChildRect.width,
        height: _currentChildRect.height,
      );
    }
    return _buildChild();
  }

  /// 构建弹层 / 列表中的 child，并挂上 [_currentChildKey] 以支持 showChildTop reparent。
  Widget _buildChild() {
    final Widget child = widget.childBuilder != null
        ? widget.childBuilder!(
            context,
            _menuController,
            _menuController.data,
          )
        : widget.child!;
    return KeyedSubtree(
      key: _currentChildKey,
      child: child,
    );
  }

  /// check and show popup menu
  /// 检查并决定是否展示弹窗
  void _checkNeedShowOrNot() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ///展示之前的数据
      if (_menuController._currentIsShow) {
        _menuController.show(data: _menuController._currentData);
      }
    });
  }

  /// update current child rect
  /// 更新当前 child 的位置和尺寸
  bool _updateCurrentRect() {
    final Rect? rect = _anchorScope.globalRect();
    if (rect == null) {
      return false;
    }
    _currentChildRect = rect;
    return true;
  }

  /// recalculate translation begin offset for hide
  /// 在隐藏前根据最新 child 位置重新计算回退偏移
  void _refreshTranslationForHide() {
    ///在被弹出新界面覆盖的情况下，不做回位动画，因为pushRoute后这个位置可能很奇怪。
    if (widget.type == BubblePopupMenuType.layer) {
      final bool isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrent) {
        return;
      }
    }

    ///更新当前的最新rect
    _updateCurrentRect();

    final Rect rect = _currentChildRect;
    final Rect bigRect = Rect.fromLTWH(
      widget.boundaryPadding.left,
      widget.boundaryPadding.top,
      MediaQuery.of(context).size.width -
          widget.boundaryPadding.left -
          widget.boundaryPadding.right,
      MediaQuery.of(context).size.height -
          widget.boundaryPadding.top -
          widget.boundaryPadding.bottom,
    );
    final double menuWidth = _currentPopupRect?.width ?? 0;
    final double menuHeight = _currentPopupRect?.height ?? 0;
    final double headerWidth = _currentHeaderRect?.width ?? 0;
    final double headerHeight = _currentHeaderRect?.height ?? 0;
    final Rect totalRect = Rect.fromLTWH(
      0,
      0,
      max(max(menuWidth, headerWidth), rect.width),
      headerHeight + rect.height + menuHeight,
    );
    final bool showDown;
    switch (widget.direction) {
      case BubblePopupMenuDirection.down:
        showDown = true;
        break;
      case BubblePopupMenuDirection.up:
        showDown = false;
        break;
      case BubblePopupMenuDirection.auto:
        showDown = (bigRect.bottom - rect.top - rect.height) >=
            (rect.top - bigRect.top);
        break;
    }
    final double left;
    switch (widget.align) {
      case BubblePopupMenuAlign.center:
        left = rect.left + rect.width / 2 - totalRect.width / 2;
        break;
      case BubblePopupMenuAlign.start:
        left = rect.left;
        break;
      case BubblePopupMenuAlign.end:
        left = rect.right - totalRect.width;
        break;
    }
    final double childTopInset = showDown ? headerHeight : menuHeight;
    final Offset pos = Offset(
      left,
      rect.top - childTopInset,
    );
    final Offset posLimit =
        constrainRectWithinRect(bigRect, totalRect, pos, showDown);

    _translationBeginOffset = Offset(
      pos.dx - posLimit.dx,
      pos.dy - posLimit.dy,
    );
  }

  /// measure popup size
  /// 测量弹窗尺寸，并判断是否需要重新更新布局
  void _checkPopupRelayout() {
    /// 已经清空
    if (!mounted) {
      return;
    }
    bool needRebuild = false;

    /// measure menu
    /// 测量 menu
    final RenderBox? menuRenderBox =
        _popupMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset menuOffset =
        menuRenderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Rect newMenuRect = Rect.fromLTWH(
      menuOffset.dx,
      menuOffset.dy,
      menuRenderBox?.size.width ?? 0,
      menuRenderBox?.size.height ?? 0,
    );
    if (_currentPopupRect == null || newMenuRect != _currentPopupRect) {
      _currentPopupRect = newMenuRect;
      needRebuild = true;
    }

    /// measure header
    /// 测量 header
    final RenderBox? headerRenderBox =
        _popupHeaderKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset headerOffset =
        headerRenderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Rect newHeaderRect = Rect.fromLTWH(
      headerOffset.dx,
      headerOffset.dy,
      headerRenderBox?.size.width ?? 0,
      headerRenderBox?.size.height ?? 0,
    );
    if (_currentHeaderRect == null || newHeaderRect != _currentHeaderRect) {
      _currentHeaderRect = newHeaderRect;
      needRebuild = true;
    }

    /// 需要更新,执行界面刷新
    if (needRebuild) {
      _currentFrameController.refresh();
    }
  }

  /// show overlay
  /// 显示 overlay
  void _showOverlay() {
    /// is already show
    /// 已经显示则直接返回
    if (_isLayerShow) {
      return;
    }

    /// get child size and location
    /// 获取 child 的尺寸和位置
    if (!_updateCurrentRect()) {
      return;
    }

    /// 每次打开弹层都从可见状态开始，避免复用上次滚动后的隐藏状态。
    _isPopupScrolling = false;
    _showEdgeItems = true;

    /// reset translation
    /// 重置平移动画
    _translationBeginOffset = Offset.zero;
    _translationAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _translationController,
        curve: widget.childTranslateCurve,
        reverseCurve: widget.childTranslateReverseCurve,
      ),
    );
    _translationController.reset();

    /// 展示弹层；showChildTop 时由弹层持有 [_currentChildKey]
    _isLayerShow = true;
    if (widget.showChildTop) {
      _popupOwnsChildKey = true;
    }
    if (mounted) {
      setState(() {});
    }

    /// show overlay later
    /// 插入 overlay
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    _currentShowOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          top: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: BubbleDialogFrame(
            controller: _currentFrameController,
            onFirstFrame: () {
              ///展示动画并计算高度
              _animationController.show();
              _animationHoverController.show();
              _checkPopupRelayout();

              ///展示了
              widget.onPopupShow?.call();
            },
            builder: (context) {
              ///构建child
              return _buildPopUpMenu();
            },
          ),
        );
      },
    );
    overlay.insert(_currentShowOverlay!);
  }

  ///直接展示dialog
  void _showDialog() {
    /// is already show
    /// 已经显示则直接返回
    if (_isDialogShow) {
      return;
    }

    /// get child size and location
    /// 获取 child 的尺寸和位置
    if (!_updateCurrentRect()) {
      return;
    }

    /// dialog 同样可能承载 overlay 布局，打开时统一复位边缘内容可见状态。
    _isPopupScrolling = false;
    _showEdgeItems = true;

    /// reset translation
    /// 重置平移动画
    _translationBeginOffset = Offset.zero;
    _translationAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _translationController,
        curve: widget.childTranslateCurve,
        reverseCurve: widget.childTranslateReverseCurve,
      ),
    );
    _translationController.reset();

    /// 展示 dialog；showChildTop 时由弹层持有 [_currentChildKey]
    _isDialogShow = true;
    if (widget.showChildTop) {
      _popupOwnsChildKey = true;
    }
    if (mounted) {
      setState(() {});
    }

    ///系统返回与点击遮罩均走 [_hidePopUp]动画；barrier 不直接 pop 路由
    showGeneralDialog<void>(
      context: context,
      routeSettings: const RouteSettings(name: 'BubblePopupMenuDialog'),
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext dialogContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        ///获取当前的route
        _currentShowDialogContext = dialogContext;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop || !_isDialogShow) {
              return;
            }
            _hidePopUp(animated: _menuController._hideAnimated);
          },
          child: Material(
            color: Colors.transparent,
            child: SizedBox.expand(
              child: BubbleDialogFrame(
                controller: _currentFrameController,
                onFirstFrame: () {
                  _animationController.show();
                  _animationHoverController.show();
                  _checkPopupRelayout();
                  widget.onPopupShow?.call();
                },
                builder: (BuildContext context) {
                  return _buildPopUpMenu();
                },
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) {
        return;
      }
      _onHideSuccess();
    });
  }

  /// 关闭 dialog 路由，如果拿到了当前route,直接移除，没有拿到就pop
  void _popDialogRouteIfNeeded() {
    if (_currentShowDialogContext != null) {
      ModalRoute? route = ModalRoute.of(_currentShowDialogContext!);
      if (route != null) {
        Navigator.of(_currentShowDialogContext!, rootNavigator: true)
            .removeRoute(route);
      } else {
        Navigator.of(_currentShowDialogContext!, rootNavigator: true).pop();
      }
      _currentShowDialogContext = null;
    }
  }

  /// hide popUp
  /// 隐藏 popUp
  Future _hidePopUp({bool animated = true}) async {
    ///正在hiding
    if (_translationHiding) {
      return;
    }

    /// 弹层已被更高路由盖住时跳过退出动画，直接收尾。
    /// 否则动画易超时，并在与上层 route 重叠的 finalize 阶段抢 [_currentChildKey]。
    final bool coveredByOtherRoute = _currentShowDialogContext != null &&
        !(ModalRoute.of(_currentShowDialogContext!)?.isCurrent ?? true);

    ///不需要动画，直接隐藏
    if (!animated || coveredByOtherRoute) {
      /// 先把动画控制器复位到隐藏基准态，再卸 route。
      /// 否则 dispose/_bind(null) 会按 animation=true 把 value 恢复成 1，
      /// 导致下次长按 show 从已显示态起跳，动画与首次不一致。
      _animationController.resetToHidden();
      _animationHoverController.resetToHidden();
      _onHideSuccess();
      return;
    }

    /// 判断当前是否mounted
    if (!mounted) {
      return;
    }

    /// 在回退动画开始前，重新获取外部 child 的当前位置
    /// 并同步修正回退偏移
    _refreshTranslationForHide();

    ///当前正在hiding
    _translationHiding = true;

    ///刷新一次
    _currentFrameController.refresh();
    final List<Future<dynamic>> futureList = <Future<dynamic>>[];

    ///回退动画
    futureList.add(_animationController.hide());
    futureList.add(_animationHoverController.hide());

    ///回退transition动画
    if (mounted && _translationBeginOffset != Offset.zero) {
      _translationAnimation = Tween<Offset>(
        begin: _translationAnimation.value,
        end: _translationBeginOffset,
      ).animate(
        CurvedAnimation(
          parent: _translationController,
          curve: widget.childTranslateCurve,
          reverseCurve: widget.childTranslateReverseCurve,
        ),
      );
      _translationController.stop();
      _translationController.reset();
      futureList.add(_translationController.forward());
    }

    ///回退滚动动画（仅可滚动模式）
    if (widget.layoutMode == BubblePopupMenuLayoutMode.scroll &&
        _scrollController.hasClients) {
      futureList.add(
        _scrollController.animateTo(
          0,
          duration: widget.bubbleAnimDuration,
          curve: widget.childTranslateReverseCurve,
        ),
      );
    }

    ///执行回退；超时则直接进入收尾，避免卡在 hiding 状态
    await Future.wait(futureList).timeout(
      widget.bubbleAnimDuration,
      onTimeout: () => <dynamic>[],
    );

    if (!mounted) {
      return;
    }

    ///隐藏成功，执行success
    _onHideSuccess();
  }

  /// 移除 overlay / dialog 并复位业务状态（不操作 [AnimationController]）
  void _cleanupPopupShell() {
    /// showChildTop：先释放弹层侧 GlobalKey，再卸 route；列表归还延后到下一帧
    if (widget.showChildTop && _popupOwnsChildKey) {
      _popupOwnsChildKey = false;
      _currentFrameController.refresh();
    }

    if (_isLayerShow) {
      _currentShowOverlay?.remove();
      _currentShowOverlay = null;
      _isLayerShow = false;
    }

    if (_isDialogShow) {
      /// 先 removeRoute，再清标记，避免列表与弹层同帧挂同一 GlobalKey
      _popDialogRouteIfNeeded();
      _isDialogShow = false;
    }

    _menuController._currentIsShow = false;
    _menuController._clearData();

    /// 恢复默认隐藏动画策略，避免上次 hide(animated: false) 污染后续关闭。
    _menuController._hideAnimated = true;
    _translationHiding = false;
    _currentPopupRect = null;
    _currentHeaderRect = null;
    _cacheMenus = null;
    _popupOwnsChildKey = false;
    _translationBeginOffset = Offset.zero;

    /// 清理时复位边缘内容状态，下一次展示不继承上次的滚动结果。
    _isPopupScrolling = false;
    _showEdgeItems = true;
  }

  /// 平移动画归位（须在 [AnimationController.dispose] 之前且 [mounted] 为 true 时调用）
  void _resetTranAnimation() {
    if (!mounted) {
      return;
    }
    _translationAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _translationController,
        curve: widget.childTranslateCurve,
        reverseCurve: widget.childTranslateReverseCurve,
      ),
    );
    _translationController.reset();
  }

  /// 隐藏完成：移除 shell、复位状态（可重入，仅执行一次）
  void _onHideSuccess() {
    if (_isCleaningUp) {
      return;
    }
    if (!_isLayerShow && !_isDialogShow) {
      return;
    }
    _isCleaningUp = true;
    final bool deferChildReclaim = widget.showChildTop;
    try {
      _cleanupPopupShell();
      _resetTranAnimation();
      void finish() {
        if (mounted) {
          setState(() {});
        }
        widget.onPopupHide?.call();
        _isCleaningUp = false;
      }

      if (deferChildReclaim) {
        /// 等本帧弹层卸载完成，再让列表挂回 [_currentChildKey]
        WidgetsBinding.instance.addPostFrameCallback((_) => finish());
      } else {
        finish();
      }
    } catch (_) {
      _isCleaningUp = false;
      rethrow;
    }
  }

  /// divider height
  /// 分割线高度
  double _getDividerHeight() {
    return 1 / MediaQuery.of(context).devicePixelRatio;
  }

  /// build separators
  /// 构建带分割线的列表
  List<Widget> createListWithSeparators(List<Widget> originalList) {
    final List<Widget> listWithSeparators = [];
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

  /// build popup menu
  /// 构建弹窗容器
  Widget _buildPopUpMenu() {
    /// translucent
    /// 穿透
    if (widget.translucent) {
      return _buildContent();
    }

    /// non-translucent with tap barrier
    /// 不穿透时增加点击关闭逻辑
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.barrierDismissible) {
          _menuController.hide(animated: true);
        }
      },
      child: _buildContent(),
    );
  }

  /// build content
  /// 构建弹窗内容
  Widget _buildContent() {
    /// build menus
    /// 构建菜单
    _cacheMenus ??= widget.menusBuilder(
      context,
      _menuController,
      _menuController.data,
    );

    /// offset
    /// child 的原始位置
    final Rect rect = _currentChildRect;

    /// overlay boundary rect
    /// 计算整体可用边界
    final Rect bigRect = Rect.fromLTWH(
      widget.boundaryPadding.left,
      widget.boundaryPadding.top,
      MediaQuery.of(context).size.width -
          widget.boundaryPadding.left -
          widget.boundaryPadding.right,
      MediaQuery.of(context).size.height -
          widget.boundaryPadding.top -
          widget.boundaryPadding.bottom,
    );

    /// total popup size
    /// 计算整体内容尺寸
    final double menuWidth = _currentPopupRect?.width ?? 0;
    final double menuHeight = _currentPopupRect?.height ?? 0;
    final double headerWidth = _currentHeaderRect?.width ?? 0;
    final double headerHeight = _currentHeaderRect?.height ?? 0;
    final Rect totalRect = Rect.fromLTWH(
      0,
      0,
      max(max(menuWidth, headerWidth), rect.width),
      headerHeight + rect.height + menuHeight,
    );

    /// decide popup direction
    /// 计算是显示在上方还是下方
    final bool showDown;
    switch (widget.direction) {
      case BubblePopupMenuDirection.down:
        showDown = true;
        break;
      case BubblePopupMenuDirection.up:
        showDown = false;
        break;
      case BubblePopupMenuDirection.auto:
        showDown = (bigRect.bottom - rect.top - rect.height) >=
            (rect.top - bigRect.top);
        break;
    }

    /// calculate horizontal position
    /// 计算整体布局的横向位置
    final double left;
    switch (widget.align) {
      case BubblePopupMenuAlign.center:
        left = rect.left + rect.width / 2 - totalRect.width / 2;
        break;
      case BubblePopupMenuAlign.start:
        left = rect.left;
        break;
      case BubblePopupMenuAlign.end:
        left = rect.right - totalRect.width;
        break;
    }

    /// child top inset in total column
    /// child 在整体 Column 中距离顶部的偏移
    final double childTopInset = showDown ? headerHeight : menuHeight;

    /// keep child position unchanged
    /// 保证 child 的位置尽量不发生变化
    final Offset pos = Offset(
      left,
      rect.top - childTopInset,
    );

    /// constrain popup within boundary
    /// 将整体布局限制在边界内
    final Offset posLimit =
        constrainRectWithinRect(bigRect, totalRect, pos, showDown);

    /// calculate bubble arrow delta
    /// 计算气泡箭头偏移
    final double delta;
    switch (widget.align) {
      case BubblePopupMenuAlign.start:
        delta = min(menuWidth / 2, rect.width / 2);
        break;
      case BubblePopupMenuAlign.end:
        delta = menuWidth - min(menuWidth / 2, rect.width / 2);
        break;
      case BubblePopupMenuAlign.center:
        delta = menuWidth / 2;
        break;
    }

    final List<Widget> menus = _cacheMenus ?? [];

    /// overlay 模式不改变原布局，仅把超出可视区的 menu 向 child 方向平移。
    final double overflowHeight = max(0, totalRect.height - bigRect.height);
    final double menuTranslateY =
        widget.layoutMode == BubblePopupMenuLayoutMode.overlay
            ? overflowHeight * (showDown ? -1 : 1)
            : 0;

    final double showPosX = posLimit.dx;
    final double showPosY = posLimit.dy;

    /// 开启 correctOverlayMaxScrollExtent 时，按 translate 后的视觉最底部
    /// 计算 overlay 模式的 maxScrollExtent。
    ///
    /// showDown 时 menu 会向上覆盖 child，不能直接从布局溢出中减去整个
    /// overflowHeight，否则 child 很高时上限会被错误压成 0，无法滚到 child
    /// 底部。这里分别计算未平移区域与已平移 menu 的视觉底边，取较大值。
    if (widget.layoutMode == BubblePopupMenuLayoutMode.overlay &&
        widget.correctOverlayMaxScrollExtent) {
      final double visualBottomInContent;
      if (showDown) {
        // Column 顺序为 header → child → menu。menu 上移后可能与 child 重叠，
        // 但 child 自身不参与 translate，因此必须保留滚到 childBottom 的距离。
        final double childBottom = headerHeight + rect.height;
        final double translatedMenuBottom = totalRect.height + menuTranslateY;
        visualBottomInContent = max(childBottom, translatedMenuBottom);
      } else {
        // Column 顺序为 menu → child → header。menu 下移可能超出原布局底边，
        // 所以在原布局底边与 translate 后 menu 底边之间取较大值。
        final double translatedMenuBottom = menuHeight + menuTranslateY;
        visualBottomInContent = max(totalRect.height, translatedMenuBottom);
      }
      // showPosY 是整块内容在屏幕中的起点；bigRect.bottom 是允许显示的
      // 最低边界。两者相减即为视觉内容完全可见所需的最大滚动距离。
      _scrollController.maxScrollExtentLimit =
          max(0.0, showPosY + visualBottomInContent - bigRect.bottom);
    } else {
      /// 默认不介入 Flutter 的滚动范围计算；infinity 在自定义 ScrollPosition
      /// 中等价于“只采用框架给出的 maxScrollExtent”。
      _scrollController.maxScrollExtentLimit = double.infinity;
    }

    /// translation animation offset
    /// 平移动画的起始偏移
    final Offset translationBeginOffset = Offset(
      pos.dx - posLimit.dx,
      pos.dy - posLimit.dy,
    );

    /// update translation animation
    /// 更新平移动画
    _updateTranslationAnimation(translationBeginOffset);

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildOverlayHover(),

          /// 空间足够：与旧模式完全同一套 Column + ScrollView + 位移动画
          _buildContentView(
            Offset(showPosX, showPosY),
            showDown,
            delta,
            menus,
            menuTranslateY,
            // overlay 下仅内容超出边界、menu 与 child 发生叠加时才允许滚动。
            allowOverlayScroll: overflowHeight > 0,
          ),
        ],
      ),
    );
  }

  /// build header
  /// 构建头部，Header只需要一个渐变动画就行
  Widget _buildHeader(bool showDown) {
    final Widget header = (widget.headerBuilder != null)
        ? widget.headerBuilder!.call(
            context,
            _menuController,
            _menuController.data,
          )
        : const SizedBox.shrink();
    return Offstage(
      offstage: _currentHeaderRect == null,
      child: UnconstrainedBox(
        child: Padding(
          key: _popupHeaderKey,
          padding: widget.headerPadding,
          child: AnimatedBuilder(
            animation: _animationController.listenable,
            builder: (context, child) {
              return Opacity(
                opacity: _animationController.value,
                child: child,
              );
            },
            child: header,
          ),
        ),
      ),
    );
  }

  ///创建menu
  Widget _buildMenu(
    bool showDown,
    double delta,
    List<Widget> menus,
  ) {
    late final Alignment animAlign;
    switch (widget.align) {
      case BubblePopupMenuAlign.start:
        animAlign = showDown ? Alignment.topLeft : Alignment.bottomLeft;
        break;
      case BubblePopupMenuAlign.end:
        animAlign = showDown ? Alignment.topRight : Alignment.bottomRight;
        break;
      case BubblePopupMenuAlign.center:
        animAlign = showDown ? Alignment.topCenter : Alignment.bottomCenter;
        break;
    }
    return Offstage(
      offstage: _currentPopupRect == null,
      child: UnconstrainedBox(
        child: Padding(
          key: _popupMenuKey,
          padding: widget.menuPadding,
          child: BubblePopupAnimation(
            controller: _animationController,
            enableScale: widget.bubbleAnimScaleEnable,
            fadeShowCurve: widget.bubbleAnimCurve,
            fadeHideCurve: widget.bubbleAnimReverseCurve,
            scaleShowCurve: widget.bubbleAnimCurve,
            scaleHideCurve: widget.bubbleAnimReverseCurve,
            duration: widget.bubbleAnimDuration,
            scaleAlignment: animAlign,
            child: _buildOverlayPopContent(
              showDown,
              delta,
              menus,
            ),
          ),
        ),
      ),
    );
  }

  /// 为 overlay 内容两端的 header / menu 添加滚动感知渐变。
  ///
  /// 使用 [AnimatedOpacity] 而非 Offstage/条件移除，确保隐藏前后占位尺寸一致；
  /// 隐藏状态下通过 [IgnorePointer] 防止透明的功能项拦截点击。
  Widget _buildScrollAwareEdgeItem(Widget child) {
    if (widget.layoutMode != BubblePopupMenuLayoutMode.overlay ||
        !widget.autoHideEdgeItemsOnScroll) {
      return child;
    }
    return IgnorePointer(
      ignoring: !_showEdgeItems,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        opacity: _showEdgeItems ? 1 : 0,
        child: child,
      ),
    );
  }

  /// build content view
  /// 构建内容视图
  Widget _buildContentView(
    Offset offset,
    bool showDown,
    double delta,
    List<Widget> menus,
    double menuTranslateY, {
    bool allowOverlayScroll = false,
  }) {
    /// animation anchor and cross axis
    /// 计算动画基准方向和交叉轴对齐
    late final CrossAxisAlignment crossAxisAlignment;
    switch (widget.align) {
      case BubblePopupMenuAlign.start:
        crossAxisAlignment = CrossAxisAlignment.start;
        break;
      case BubblePopupMenuAlign.end:
        crossAxisAlignment = CrossAxisAlignment.end;
        break;
      case BubblePopupMenuAlign.center:
        crossAxisAlignment = CrossAxisAlignment.center;
        break;
    }

    /// 顶部 header：滚动查看 child 时按阈值渐隐。
    final Widget headerView = _buildScrollAwareEdgeItem(
      _buildHeader(showDown),
    );

    /// 弹层中的 child 预览（showChildTop）
    final Widget childView = SizedBox(
      width: _currentChildRect.width,
      height: _currentChildRect.height,
      child: widget.showChildTop
          ? IgnorePointer(
              child: HeroMode(
                enabled: false,

                /// 仅在弹层持有 key 时挂载；收尾释放后改为占位，避免与列表双挂
                child: _popupOwnsChildKey
                    ? _buildChild()
                    : const SizedBox.shrink(),
              ),
            )
          : const SizedBox.shrink(),
    );

    /// 功能 menu：Transform 必须位于 AnimatedOpacity 外层，使绘制位置和
    /// 命中区域一起移动；否则与 child 重叠、超出原布局区域的部分无法点击。
    final Widget menuView = Transform.translate(
      offset: Offset(0, menuTranslateY),
      child: _buildScrollAwareEdgeItem(
        _buildMenu(showDown, delta, menus),
      ),
    );

    ///子类
    final List<Widget> children;
    if (showDown) {
      children = [
        headerView,
        childView,
        menuView,
      ];
    } else {
      children = [
        menuView,
        childView,
        headerView,
      ];
    }

    /// 收起位移动画期间锁定滚动。
    /// overlay 模式仅在内容超出边界、menu 与 child 发生叠加时允许滚动回弹；
    /// 空间足够时禁用滚动，避免短内容仍可拖动。
    /// 是否额外收紧 maxScrollExtent 由 correctOverlayMaxScrollExtent 决定。
    final bool lockScroll = _translationHiding;
    final ScrollPhysics scrollPhysics;
    if (lockScroll) {
      scrollPhysics = const NeverScrollableScrollPhysics();
    } else if (widget.layoutMode == BubblePopupMenuLayoutMode.overlay) {
      scrollPhysics = allowOverlayScroll
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : const NeverScrollableScrollPhysics();
    } else {
      scrollPhysics = const BouncingScrollPhysics();
    }

    /// 通过 NotificationListener 记录完整滚动生命周期；controller listener
    /// 继续负责监听 offset，二者共同避免阈值附近反复显示/隐藏。
    return NotificationListener<ScrollNotification>(
      onNotification: _handlePopupScrollNotification,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        controller: _scrollController,
        physics: scrollPhysics,
        clipBehavior: Clip.none,
        child: Container(
          margin: EdgeInsets.fromLTRB(
            offset.dx,
            offset.dy,
            //右边需要限制一下
            widget.boundaryPadding.right,
            //底部也需要限制一下
            widget.boundaryPadding.bottom,
          ),
          child: AnimatedBuilder(
            animation: _translationAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _translationAnimation.value,
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  /// update translation animation
  /// 更新平移动画
  void _updateTranslationAnimation(Offset newBeginOffset) {
    if (!mounted || _translationHiding) {
      return;
    }
    if (_translationBeginOffset == newBeginOffset) {
      return;
    }
    _translationBeginOffset = newBeginOffset;
    _translationAnimation = Tween<Offset>(
      begin: newBeginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _translationController,
        curve: widget.childTranslateCurve,
        reverseCurve: widget.childTranslateReverseCurve,
      ),
    );
    _translationController
      ..stop()
      ..reset()
      ..forward();
  }

  /// build hover
  /// 构建 hover
  Widget _buildOverlayHover() {
    if (widget.hover == null) {
      return const SizedBox.shrink();
    }
    return BubblePopupAnimation(
      controller: _animationHoverController,
      duration: widget.bubbleAnimDuration,
      child: widget.hover,
    );
  }

  /// current menus
  /// 构建当前菜单内容
  Widget _buildOverlayPopContent(
    bool showDown,
    double delta,
    List<Widget> menus,
  ) {
    final PopupBubbleOptions bubbleOptions =
        widget.background.bubbleOptions ?? const PopupBubbleOptions();
    if (widget.background.decoration != null) {
      return Container(
        decoration: widget.background.decoration,
        padding: widget.bubblePadding,
        child: Column(
          verticalDirection: VerticalDirection.down,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: createListWithSeparators(menus),
        ),
      );
    }

    return BubbleContainer(
      type: showDown ? BubbleType.top : BubbleType.bottom,
      deltaOffset: delta,
      radius: bubbleOptions.bubbleRadius,
      color: bubbleOptions.bubbleColor,
      shadowColor: bubbleOptions.bubbleShadowColor,
      shadowElevation: bubbleOptions.bubbleShadowElevation,
      padding: widget.bubblePadding,
      child: Column(
        verticalDirection: VerticalDirection.down,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: createListWithSeparators(menus),
      ),
    );
  }

  /// create rect within rect
  /// 将小矩形限制在大矩形内
  Offset constrainRectWithinRect(
    Rect bigRect,
    Rect smallRect,
    Offset smallRectOffset,
    bool showDown,
  ) {
    double newDx = smallRectOffset.dx;
    double newDy = smallRectOffset.dy;

    /// horizontal constraint
    /// 水平方向限制
    final double minDx = bigRect.left;
    final double maxDx = max(bigRect.left, bigRect.right - smallRect.width);
    newDx = newDx.clamp(minDx, maxDx);

    /// vertical constraint
    /// 垂直方向限制
    final double minDy = bigRect.top;
    final double maxDy = max(bigRect.top, bigRect.bottom - smallRect.height);

    if (showDown) {
      if (newDy < minDy) {
        newDy = minDy;
      }
      if (newDy > maxDy) {
        newDy = maxDy;
      }
    } else {
      if (newDy > maxDy) {
        newDy = maxDy;
      }
      if (newDy < minDy) {
        newDy = minDy;
      }
    }
    return Offset(newDx, newDy);
  }
}

/// 可动态限制 [ScrollPosition.maxScrollExtent] 的控制器。
///
/// Transform 只改变绘制位置，不改变 ScrollView 的布局尺寸。开启
/// [BubblePopupMenu.correctOverlayMaxScrollExtent] 后，在
/// [ScrollPosition.applyContentDimensions] 阶段按视觉范围收紧上限。
class _BubblePopupScrollController extends ScrollController {
  /// 允许的最大滚动距离上限。
  ///
  /// 默认 infinity 表示不修正框架计算结果；仅在
  /// [BubblePopupMenu.correctOverlayMaxScrollExtent] 开启时写入有限值。
  double maxScrollExtentLimit = double.infinity;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _BubblePopupScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      getMaxScrollExtentLimit: () => maxScrollExtentLimit,
    );
  }
}

class _BubblePopupScrollPosition extends ScrollPositionWithSingleContext {
  _BubblePopupScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.getMaxScrollExtentLimit,
  });

  /// 每次内容尺寸计算时动态读取最新上限，支持弹层展示期间修改配置。
  final double Function() getMaxScrollExtentLimit;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    /// 参数关闭时 limit 为 infinity，limitedMax 会保持框架原始值；
    /// 参数开启时只允许缩小上限，绝不扩张原本不可滚动的内容。
    final double limit = getMaxScrollExtentLimit();
    // 不扩大框架根据布局得出的范围，只允许用视觉范围进一步收紧它。
    // BouncingScrollPhysics 仍可在边界外产生临时 overscroll，并自动回弹。
    final double limitedMax = maxScrollExtent.isFinite
        ? min(maxScrollExtent, limit)
        : (limit.isFinite ? limit : 0.0);
    return super.applyContentDimensions(minScrollExtent, max(0.0, limitedMax));
  }
}
