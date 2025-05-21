import 'package:flutter/material.dart';

/// Pop feed animation alpha controller
class PopupAnimationController {
  AnimationController? _animationController;

  bool animation;

  PopupAnimationController({
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
class PopupAnimation extends StatefulWidget {
  // Controller
  final PopupAnimationController controller;

  // On show
  final VoidCallback? onShow;

  // On hide
  final VoidCallback? onHide;

  // Child
  final Widget? child;

  const PopupAnimation({
    super.key,
    required this.controller,
    this.onShow,
    this.onHide,
    this.child,
  });

  @override
  State createState() => _PopupAnimationState();
}

/// Pop feed animation alpha state
class _PopupAnimationState extends State<PopupAnimation>
    with SingleTickerProviderStateMixin {
  /// Animation
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    /// Set the animation controller in the widget's controller
    final AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );

    /// Set the animation controller in the widget's controller
    widget.controller.setAnimationController(animationController);

    /// Animation
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onShow?.call();
            } else if (status == AnimationStatus.dismissed) {
              widget.onHide?.call();
            }
          });

    /// Start the animation to show the widget
    if (widget.controller.animation) {
      animationController.forward();
    }
  }

  @override
  void dispose() {
    widget.controller._animationController?.dispose();
    widget.controller.setAnimationController(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _animation.value == 0
        ? Visibility(
            visible: false,
            maintainSemantics: true,
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            child: Opacity(
              opacity: _animation.value,
              child: widget.child ?? const SizedBox(),
            ),
          )
        : Opacity(
            opacity: _animation.value,
            child: widget.child ?? const SizedBox(),
          );
  }
}
