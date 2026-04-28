import 'package:flutter/material.dart';

/// Pop feed animation alpha controller
class BubblePopupAnimationController {
  AnimationController? _animationController;
  bool animation;

  BubblePopupAnimationController({
    this.animation = false,
  });

  void setAnimationController(AnimationController? controller) {
    _animationController = controller;
  }

  bool get isVisible => _animationController?.isCompleted ?? false;

  void show() {
    animation = true;
    _animationController?.forward();
  }

  void hide() {
    animation = false;
    _animationController?.reverse();
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
