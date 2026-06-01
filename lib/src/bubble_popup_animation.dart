import 'package:flutter/material.dart';

/// Pop feed animation alpha controller
/// 弹窗动画控制器
///
/// 该控制器本身不直接创建动画，而是作为外部统一控制入口，
/// 持有内部 [AnimationController] 的引用，供外部调用 show / hide。
///
/// 典型用途：
/// - 由外部在弹窗显示时调用 [show]
/// - 在弹窗隐藏时调用 [hide]
/// - 在需要读取当前动画进度时使用 [value]
/// - 在需要监听动画刷新的场景下使用 [listenable]
///
/// 注意：
/// 1. 当前实现是“一对一绑定”；
/// 2. 一个 [BubblePopupAnimationController] 只能绑定一个内部
///    [AnimationController]；
/// 3. 如果多个 [BubblePopupAnimation] 共用同一个 controller，
///    后绑定的实例会覆盖前一个绑定。
class BubblePopupAnimationController {
  /// Internal animation controller
  /// 内部真正执行动画的控制器
  AnimationController? _animationController;

  /// Whether target state is showing
  /// 当前目标状态是否为显示
  ///
  /// true 表示目标状态为显示；
  /// false 表示目标状态为隐藏。
  ///
  /// 当 widget 初始化时，如果该值已经为 true，
  /// 对应动画组件会自动执行 forward。
  bool animation;

  BubblePopupAnimationController({
    this.animation = false,
  });

  /// Bind internal animation controller
  /// 绑定内部动画控制器
  ///
  /// 该方法通常由 [BubblePopupAnimation] 在生命周期中调用，
  /// 一般不建议业务层手动调用。
  ///
  /// 当 widget 销毁或 controller 变更时，也会传入 null 解除绑定。
  void setAnimationController(AnimationController? controller) {
    _animationController = controller;
  }

  /// Whether animation is fully visible
  /// 当前动画是否已经完全显示
  ///
  /// 当内部 controller 处于 [AnimationStatus.completed] 时返回 true。
  /// 如果当前没有绑定 controller，则返回 false。
  bool get isVisible => _animationController?.isCompleted ?? false;

  /// Current animation progress
  /// 当前动画进度值
  ///
  /// 返回范围通常为 0.0 ~ 1.0：
  /// - 0.0 表示完全隐藏
  /// - 1.0 表示完全显示
  ///
  /// 当内部 controller 尚未绑定时：
  /// - 如果 [animation] 为 true，则返回 1.0
  /// - 如果 [animation] 为 false，则返回 0.0
  ///
  /// 这样可以在某些首帧或未挂载场景下，仍然得到一个合理的状态值。
  double get value => _animationController?.value ?? (animation ? 1.0 : 0.0);

  /// Animation listenable object
  /// 动画监听对象
  ///
  /// 可用于 [AnimatedBuilder]、[ListenableBuilder] 等需要监听刷新的场景。
  ///
  /// 例如：
  /// ```dart
  /// AnimatedBuilder(
  ///   animation: controller.listenable ?? const AlwaysStoppedAnimation(0),
  ///   builder: (context, child) {
  ///     return Opacity(
  ///       opacity: controller.value,
  ///       child: child,
  ///     );
  ///   },
  /// )
  /// ```
  ///
  /// 如果当前尚未绑定内部 controller，则返回 null。
  Listenable? get listenable => _animationController;

  /// Whether animation is currently running
  /// 当前动画是否正在执行中
  ///
  /// 当内部 controller 正在 forward 或 reverse 时返回 true。
  /// 如果当前没有绑定 controller，则返回 false。
  bool get isAnimating => _animationController?.isAnimating ?? false;

  /// Start show animation
  /// 播放显示动画
  ///
  /// 会先将 [animation] 标记为 true，
  /// 然后驱动内部 controller 执行 forward。
  ///
  /// 如果当前尚未绑定内部 controller，则返回一个已完成的 Future。
  Future show() {
    animation = true;
    return _animationController?.forward() ?? Future.value();
  }

  /// Start hide animation
  /// 播放隐藏动画
  ///
  /// 会先将 [animation] 标记为 false，
  /// 然后驱动内部 controller 执行 reverse。
  ///
  /// 如果当前尚未绑定内部 controller，则返回一个已完成的 Future。
  Future hide() {
    animation = false;
    return _animationController?.reverse() ?? Future.value();
  }
}

/// Pop feed animation alpha
class BubblePopupAnimation extends StatefulWidget {
  /// Controller
  final BubblePopupAnimationController controller;

  /// On show
  final VoidCallback? onShow;

  /// On hide
  final VoidCallback? onHide;

  /// Duration
  final Duration duration;

  /// Curve
  final Curve curve;

  /// Reverse curve
  final Curve? reverseCurve;

  /// Whether enable scale animation
  final bool enableScale;

  /// Begin scale value
  final double beginScale;

  /// Scale alignment
  final Alignment scaleAlignment;

  /// Child
  final Widget? child;

  const BubblePopupAnimation({
    super.key,
    required this.controller,
    this.onShow,
    this.onHide,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOut,
    this.reverseCurve,
    this.enableScale = false,
    this.beginScale = 0.2,
    this.scaleAlignment = Alignment.center,
    this.child,
  }) : assert(beginScale > 0, 'beginScale must be greater than 0.');

  @override
  State<BubblePopupAnimation> createState() => _BubblePopupAnimationState();
}

/// Pop feed animation alpha state
class _BubblePopupAnimationState extends State<BubblePopupAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.duration,
      vsync: this,
    );
    widget.controller.setAnimationController(_animationController);
    _buildAnimation();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onShow?.call();
      } else if (status == AnimationStatus.dismissed) {
        widget.onHide?.call();
      }
    });
    if (widget.controller.animation) {
      _animationController.forward();
    }
  }

  void _buildAnimation() {
    final Animation<double> curved = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve ?? widget.curve.flipped,
    );

    _fadeAnimation = curved;
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(covariant BubblePopupAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// 设置 duration
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
      _animationController.reverseDuration = widget.duration;
    }

    /// 重新创建 animation
    if (oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve ||
        oldWidget.beginScale != widget.beginScale) {
      _buildAnimation();
    }

    /// controller 变化了
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setAnimationController(null);
      widget.controller.setAnimationController(_animationController);

      if (widget.controller.animation && !_animationController.isCompleted) {
        _animationController.forward();
      } else if (!widget.controller.animation &&
          !_animationController.isDismissed) {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.setAnimationController(null);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child ?? const SizedBox();

    ///渐变
    Widget animatedChild = FadeTransition(
      opacity: _fadeAnimation,
      child: child,
    );

    ///开启大小
    if (widget.enableScale) {
      animatedChild = ScaleTransition(
        scale: _scaleAnimation,
        alignment: widget.scaleAlignment,
        child: animatedChild,
      );
    }

    ///构建
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final bool hidden = _animationController.value == 0;
        return Visibility(
          visible: !hidden,
          maintainSemantics: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: animatedChild,
        );
      },
    );
  }
}
