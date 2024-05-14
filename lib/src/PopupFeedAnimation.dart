import 'package:flutter/material.dart';


///pop feed animation alpha controller
class PopupMenuController {
  AnimationController? _animationController;

  void _setAnimationController(AnimationController? controller) {
    _animationController = controller;
  }

  bool get isVisible => _animationController?.isCompleted ?? false;

  void show() {
    _animationController?.forward();
  }

  void hide() {
    _animationController?.reverse();
  }
}


///pop feed animation alpha
class PopupFeedAnimation extends StatefulWidget {
  //controller
  final PopupMenuController controller;

  //on show
  final VoidCallback? onShow;

  //on hide
  final VoidCallback? onHide;

  //child
  final Widget? child;

  const PopupFeedAnimation({
    super.key,
    required this.controller,
    this.onShow,
    this.onHide,
    this.child,
  });

  @override
  State createState() => _PopupFeedAnimationState();
}

///pop feed animation alpha state
class _PopupFeedAnimationState extends State<PopupFeedAnimation> with SingleTickerProviderStateMixin {
  ///animation
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    ///Set the animation controller in the widget's controller
    final AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );

    ///Set the animation controller in the widget's controller
    widget.controller._setAnimationController(animationController);

    ///animation
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(animationController)
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

    ///Start the animation to show the widget
    animationController.forward();
  }

  @override
  void dispose() {
    widget.controller._setAnimationController(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _animation.value,
      child: widget.child,
    );
  }
}
