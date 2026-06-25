import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///一个可复用的点击容器。
///
///交互策略：
///- 开启水波纹时：使用 `Material + InkWell`
///- 关闭水波纹时：使用 `FocusableActionDetector + GestureDetector + Listener`
///
///这样既能保留 Material 风格交互，也能在无 splash 时获得更及时的按下反馈。
class PressableInkWell extends StatefulWidget {
  const PressableInkWell({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.pressedColor,
    this.disabledColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.enableSplashEffect = false,
    this.enablePressedEffect = true,
    this.enabled = true,
    this.duration = Duration.zero,
    this.curve = Curves.easeOut,
    this.hoverColor,
    this.focusColor,
    this.mouseCursor,
    this.semanticLabel,
    this.semanticButton = true,
    this.autofocus = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.enableFeedback = true,
    this.behavior = HitTestBehavior.opaque,
  });

  ///子组件内容。
  final Widget child;

  ///点击回调。
  final VoidCallback? onTap;

  ///长按回调。
  final VoidCallback? onLongPress;

  ///双击回调。
  final VoidCallback? onDoubleTap;

  ///外层区域宽度。
  final double? width;

  ///外层区域高度。
  final double? height;

  ///内边距。
  final EdgeInsetsGeometry? padding;

  ///外边距。
  final EdgeInsetsGeometry? margin;

  ///正常状态下的背景色。
  final Color backgroundColor;

  ///按下状态下的背景色。
  ///
  ///不传时会根据 [backgroundColor] 自动生成。
  final Color? pressedColor;

  ///禁用状态下的背景色。
  ///
  ///不传时会退回使用 [backgroundColor]。
  final Color? disabledColor;

  ///圆角。
  final BorderRadius? borderRadius;

  ///边框。
  final BoxBorder? border;

  ///阴影。
  final List<BoxShadow>? boxShadow;

  ///是否启用水波纹效果。
  final bool enableSplashEffect;

  ///是否启用按下态效果。
  final bool enablePressedEffect;

  ///是否启用交互。
  final bool enabled;

  ///按下态切换动画时长。
  ///
  ///- 大于 0：使用 [AnimatedContainer]
  ///- 等于 0：使用普通 [Container]
  final Duration duration;

  ///按下态切换动画曲线。
  final Curve curve;

  ///hover 状态颜色。
  final Color? hoverColor;

  ///focus 状态颜色。
  final Color? focusColor;

  ///鼠标样式。
  final MouseCursor? mouseCursor;

  ///语义标签。
  final String? semanticLabel;

  ///是否在语义层声明为按钮。
  final bool semanticButton;

  ///是否自动获取焦点。
  final bool autofocus;

  ///外部传入的焦点节点。
  final FocusNode? focusNode;

  ///是否允许请求焦点。
  final bool canRequestFocus;

  ///是否启用点击反馈（声音 / 震动等，依平台而定）。
  final bool enableFeedback;

  ///命中测试行为。
  final HitTestBehavior behavior;

  @override
  State<PressableInkWell> createState() => _PressableInkWellState();
}

class _PressableInkWellState extends State<PressableInkWell> {
  ///用于获取当前组件的渲染区域。
  ///
  ///在无 splash 模式下，需要根据它判断 pointer 是否仍在组件内部，
  ///从而实现“滑出取消 pressed，滑回恢复 pressed”。
  final GlobalKey _regionKey = GlobalKey();

  ///当前是否处于按下态。
  ///
  ///仅用于视觉反馈，不参与点击判定。
  bool _pressed = false;

  ///当前是否处于 hover 状态。
  bool _hovered = false;

  ///当前是否处于 focus 状态。
  bool _focused = false;

  ///当前是否存在一个由本组件追踪的按下指针。
  bool _pointerActive = false;

  ///当前按下指针是否仍在组件区域内。
  bool _pointerInside = false;

  ///当前是否可交互。
  ///
  ///只有同时满足以下条件时才认为可交互：
  ///1. [widget.enabled] 为 true
  ///2. 至少存在一个交互回调
  bool get _interactive {
    if (!widget.enabled) {
      return false;
    }
    return widget.onTap != null ||
        widget.onLongPress != null ||
        widget.onDoubleTap != null;
  }

  ///当前是否启用隐式动画。
  bool get _enableAnimation {
    return widget.duration > Duration.zero;
  }

  ///统一处理圆角，避免多处判空。
  BorderRadius get _borderRadius {
    return widget.borderRadius ?? BorderRadius.zero;
  }

  ///解析鼠标样式。
  ///
  ///可交互时默认使用 click，不可交互时使用 basic。
  MouseCursor get _resolvedMouseCursor {
    return widget.mouseCursor ??
        (_interactive ? SystemMouseCursors.click : SystemMouseCursors.basic);
  }

  ///更新 pressed 状态。
  ///
  ///做重复值判断，避免无意义的 `setState`。
  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  ///更新 hovered 状态。
  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _hovered = value;
    });
  }

  ///更新 focused 状态。
  void _setFocused(bool value) {
    if (_focused == value) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _focused = value;
    });
  }

  ///重置 pointer 相关状态。
  ///
  ///用于 pointer up / cancel / 组件失活等场景。
  void _resetPointerState() {
    _pointerActive = false;
    _pointerInside = false;
    _setPressed(false);
  }

  ///根据基础背景色生成默认按下态颜色。
  Color _defaultPressedColor(Color baseColor) {
    return Color.alphaBlend(
      Colors.black.withValues(alpha: 0.08),
      baseColor,
    );
  }

  ///根据基础背景色生成默认 hover 颜色。
  Color _defaultHoverColor(Color baseColor) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.04),
      baseColor,
    );
  }

  ///根据基础背景色生成默认 focus 颜色。
  Color _defaultFocusColor(Color baseColor) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.06),
      baseColor,
    );
  }

  ///判断当前 pointer 是否仍在组件区域内。
  ///
  ///这里通过 RenderBox 将全局坐标转换为本地坐标，再判断是否落在组件矩形范围内。
  bool _isPointerInside(PointerEvent event) {
    final context = _regionKey.currentContext;
    if (context == null) {
      return false;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final localPosition = renderObject.globalToLocal(event.position);
    final rect = Offset.zero & renderObject.size;
    return rect.contains(localPosition);
  }

  ///指针按下时进入 pressed。
  ///
  ///无 splash 模式下直接监听 pointer down，
  ///这样按下反馈会比依赖 InkWell highlight 更及时。
  void _handlePointerDown(PointerDownEvent event) {
    if (!_interactive || !widget.enablePressedEffect) {
      return;
    }

    _pointerActive = true;
    _pointerInside = true;
    _setPressed(true);
  }

  ///指针移动时同步更新 pressed 状态。
  ///
  ///- 在区域内：保持 pressed
  ///- 滑出区域：取消 pressed
  ///- 滑回区域：恢复 pressed
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_interactive || !widget.enablePressedEffect) {
      return;
    }
    if (!_pointerActive) {
      return;
    }

    final inside = _isPointerInside(event);
    if (_pointerInside == inside) {
      return;
    }

    _pointerInside = inside;
    _setPressed(inside);
  }

  ///指针抬起时重置 pressed。
  void _handlePointerUp(PointerUpEvent event) {
    if (!_interactive || !widget.enablePressedEffect) {
      return;
    }
    _resetPointerState();
  }

  ///指针取消时重置 pressed。
  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_interactive || !widget.enablePressedEffect) {
      return;
    }
    _resetPointerState();
  }

  ///统一处理点击。
  ///
  ///这里会补充平台反馈能力。
  void _handleTap() {
    if (!_interactive || widget.onTap == null) {
      return;
    }

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }
    widget.onTap?.call();
  }

  ///统一处理长按。
  void _handleLongPress() {
    if (!_interactive || widget.onLongPress == null) {
      return;
    }

    if (widget.enableFeedback) {
      Feedback.forLongPress(context);
    }
    widget.onLongPress?.call();
  }

  ///统一处理键盘激活行为。
  ///
  ///在无 splash 模式下，通过 Enter / Space 触发点击。
  void _handleActivateIntent() {
    _handleTap();
  }

  ///解析当前实际显示的背景色。
  ///
  ///状态优先级：
  ///disabled > pressed > focused > hovered > normal
  Color _resolveBackgroundColor() {
    final normalColor = _interactive
        ? widget.backgroundColor
        : (widget.disabledColor ?? widget.backgroundColor);

    if (!_interactive) {
      return normalColor;
    }

    if (widget.enablePressedEffect && _pressed) {
      return widget.pressedColor ??
          _defaultPressedColor(widget.backgroundColor);
    }

    if (_focused) {
      return widget.focusColor ?? _defaultFocusColor(normalColor);
    }

    if (_hovered) {
      return widget.hoverColor ?? _defaultHoverColor(normalColor);
    }

    return normalColor;
  }

  ///构建视觉层。
  ///
  ///这里只负责尺寸、边距、背景、圆角、边框和阴影，
  ///不负责点击逻辑。
  Widget _buildDecoratedChild() {
    final decoration = BoxDecoration(
      color: _resolveBackgroundColor(),
      borderRadius: _borderRadius,
      border: widget.border,
      boxShadow: widget.boxShadow,
    );

    if (_enableAnimation) {
      return AnimatedContainer(
        key: _regionKey,
        duration: widget.duration,
        curve: widget.curve,
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        margin: widget.margin,
        decoration: decoration,
        child: widget.child,
      );
    }

    return Container(
      key: _regionKey,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      margin: widget.margin,
      decoration: decoration,
      child: widget.child,
    );
  }

  ///构建 InkWell 模式。
  ///
  ///适用于启用 splash 的场景，保留 Material 风格交互。
  Widget _buildInkWellMode() {
    return Material(
      color: Colors.transparent,
      borderRadius: _borderRadius,
      clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: _interactive ? _handleTap : null,
        onLongPress: _interactive ? _handleLongPress : null,
        onDoubleTap: _interactive ? widget.onDoubleTap : null,
        onHighlightChanged: widget.enablePressedEffect ? _setPressed : null,
        borderRadius: _borderRadius,
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        mouseCursor: _resolvedMouseCursor,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        canRequestFocus: widget.canRequestFocus && _interactive,
        enableFeedback: widget.enableFeedback,
        onHover: _setHovered,
        onFocusChange: _setFocused,
        child: _buildDecoratedChild(),
      ),
    );
  }

  ///构建无 splash 的 pointer 模式。
  ///
  ///- `FocusableActionDetector`：负责 hover / focus / keyboard
  ///- `GestureDetector`：负责 tap / longPress / doubleTap
  ///- `Listener`：负责更及时的 pressed 状态同步
  Widget _buildPointerMode() {
    return FocusableActionDetector(
      enabled: _interactive,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      mouseCursor: _resolvedMouseCursor,
      onShowHoverHighlight: _setHovered,
      onShowFocusHighlight: _setFocused,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            _handleActivateIntent();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: _interactive ? _handleTap : null,
        onLongPress: _interactive ? _handleLongPress : null,
        onDoubleTap: _interactive ? widget.onDoubleTap : null,
        child: Listener(
          behavior: widget.behavior,
          onPointerDown: _interactive && widget.enablePressedEffect
              ? _handlePointerDown
              : null,
          onPointerMove: _interactive && widget.enablePressedEffect
              ? _handlePointerMove
              : null,
          onPointerUp: _interactive && widget.enablePressedEffect
              ? _handlePointerUp
              : null,
          onPointerCancel: _interactive && widget.enablePressedEffect
              ? _handlePointerCancel
              : null,
          child: _buildDecoratedChild(),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PressableInkWell oldWidget) {
    super.didUpdateWidget(oldWidget);

    ///当组件从可交互变成不可交互时，及时清理内部按下状态。
    if (!_interactive) {
      _resetPointerState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child =
        widget.enableSplashEffect ? _buildInkWellMode() : _buildPointerMode();

    ///统一补一层语义，保证两种模式下的无障碍表现更一致。
    return Semantics(
      button: widget.semanticButton,
      enabled: _interactive,
      label: widget.semanticLabel,
      onTap: _interactive ? _handleTap : null,
      child: child,
    );
  }
}
