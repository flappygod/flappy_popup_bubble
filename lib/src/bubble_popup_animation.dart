import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Bubble popup animation controller
/// 气泡弹窗动画控制器
///
/// 该控制器作为外部统一控制入口：
/// - 提供 show / hide 方法
/// - 提供当前动画值 value
/// - 提供是否可见 isVisible
/// - 提供是否正在执行动画 isAnimating
/// - 自身实现了 [ChangeNotifier]，因此也可直接作为 [Listenable] 使用
///
/// 与传统“直接暴露 AnimationController”的方式不同，
/// 这里 controller 不再持有单一的 AnimationController，
/// 而是由内部 State 维护两个控制器：
/// - 一个负责 show
/// - 一个负责 hide
///
/// 这样做的好处是：
/// 1. show / hide 逻辑完全分离；
/// 2. hide 时可以从“当前值”开始，而不是依赖 reverse；
/// 3. 避免复杂 reverseCurve 在中途打断时产生异常视觉效果；
/// 4. 外部仍可通过 [listenable] 监听动画逐帧变化。
///
/// 注意：
/// - controller.value 表示“可见进度”，范围固定为 0.0 ~ 1.0；
/// - scale 动画内部允许大于 1.0，以保留如 easeOutBack 的 overshoot 效果。
class BubblePopupAnimationController extends ChangeNotifier {
  /// Bound widget state
  /// 当前绑定的动画组件状态对象
  _BubblePopupAnimationState? _state;

  /// Target animation state
  /// 当前目标状态
  ///
  /// true 表示目标为显示；
  /// false 表示目标为隐藏。
  bool animation;

  /// Current visible progress
  /// 当前可见进度值，范围固定为 0.0 ~ 1.0
  double _value;

  /// Whether animation is running
  /// 当前是否正在执行动画
  bool _isAnimating;

  /// Whether popup is fully visible
  /// 当前是否已经完全显示
  bool _isVisible;

  BubblePopupAnimationController({
    this.animation = false,
  })  : _value = animation ? 1.0 : 0.0,
        _isAnimating = false,
        _isVisible = animation;

  /// Bind state
  /// 绑定内部状态对象
  ///
  /// 由 [BubblePopupAnimation] 在生命周期中自动调用。
  void _bind(_BubblePopupAnimationState? state) {
    _state = state;
    _syncFromState();
  }

  /// Sync controller state
  /// 同步控制器状态
  ///
  /// 仅当状态发生变化时才触发 [notifyListeners]。
  void _sync({
    required double value,
    required bool isAnimating,
    required bool isVisible,
  }) {
    final bool changed = _value != value ||
        _isAnimating != isAnimating ||
        _isVisible != isVisible;

    _value = value;
    _isAnimating = isAnimating;
    _isVisible = isVisible;

    if (changed) {
      notifyListeners();
    }
  }

  /// Sync from bound state
  /// 从当前绑定的 State 同步状态
  void _syncFromState() {
    final state = _state;
    if (state == null) {
      _sync(
        value: animation ? 1.0 : 0.0,
        isAnimating: false,
        isVisible: animation,
      );
      return;
    }

    _sync(
      value: state.currentValue.clamp(0.0, 1.0).toDouble(),
      isAnimating: state.isAnimating,
      isVisible: state.currentValue >= 1.0,
    );
  }

  /// Whether popup is fully visible
  /// 当前是否已经完全显示
  bool get isVisible => _isVisible;

  /// Current visible progress
  /// 当前可见进度值，范围固定为 0.0 ~ 1.0
  double get value => _value;

  /// Listenable object
  /// 监听对象
  ///
  /// controller 自身继承自 [ChangeNotifier]，
  /// 因此这里直接返回 this。
  Listenable get listenable => this;

  /// Whether animation is currently running
  /// 当前是否正在执行动画
  bool get isAnimating => _isAnimating;

  /// Show popup
  /// 执行显示动画
  Future<void> show() {
    animation = true;
    final state = _state;
    if (state == null) {
      _sync(
        value: 1,
        isAnimating: false,
        isVisible: true,
      );
      return Future.value();
    }
    return state.show();
  }

  /// Hide popup
  /// 执行隐藏动画
  Future<void> hide() {
    animation = false;
    final state = _state;
    if (state == null) {
      _sync(
        value: 0,
        isAnimating: false,
        isVisible: false,
      );
      return Future.value();
    }
    return state.hide();
  }

  /// Instantly reset to hidden baseline without playing hide animation.
  /// 无动画复位到隐藏基准态，避免下次 show 从 value=1 起跳。
  void resetToHidden() {
    animation = false;
    final state = _state;
    if (state != null) {
      state._jumpToHidden();
    } else {
      _sync(
        value: 0,
        isAnimating: false,
        isVisible: false,
      );
    }
  }
}

/// Bubble popup animation widget
/// 气泡弹窗动画组件
///
/// 支持：
/// - 透明度动画（fade）
/// - 缩放动画（scale，可选）
///
/// 内部使用两个控制器：
/// - showController：负责显示动画
/// - hideController：负责隐藏动画
///
/// 这样在“显示过程中立刻隐藏”时，
/// hide 可以从当前值平滑开始，而不是依赖 reverse。
class BubblePopupAnimation extends StatefulWidget {
  /// External controller
  /// 外部控制器
  final BubblePopupAnimationController controller;

  /// Callback when show animation completed
  /// 显示动画完成回调
  final VoidCallback? onShow;

  /// Callback when hide animation completed
  /// 隐藏动画完成回调
  final VoidCallback? onHide;

  /// Animation duration
  /// 动画时长
  final Duration duration;

  /// Fade show curve
  /// 透明度显示曲线
  final Curve fadeShowCurve;

  /// Fade hide curve
  /// 透明度隐藏曲线
  final Curve fadeHideCurve;

  /// Scale show curve
  /// 缩放显示曲线
  final Curve scaleShowCurve;

  /// Scale hide curve
  /// 缩放隐藏曲线
  final Curve scaleHideCurve;

  /// Whether enable scale animation
  /// 是否启用缩放动画
  final bool enableScale;

  /// Begin scale value
  /// 缩放起始值
  final double beginScale;

  /// Scale alignment
  /// 缩放对齐点
  final Alignment scaleAlignment;

  /// Child widget
  /// 子组件
  final Widget? child;

  const BubblePopupAnimation({
    super.key,
    required this.controller,
    this.onShow,
    this.onHide,
    this.duration = const Duration(milliseconds: 260),
    this.fadeShowCurve = Curves.easeOut,
    this.fadeHideCurve = Curves.easeIn,
    this.scaleShowCurve = Curves.easeOutBack,
    this.scaleHideCurve = Curves.easeInCubic,
    this.enableScale = false,
    this.beginScale = 0.0,
    this.scaleAlignment = Alignment.center,
    this.child,
  });

  @override
  State<BubblePopupAnimation> createState() => _BubblePopupAnimationState();
}

/// Bubble popup animation state
/// 气泡弹窗动画状态实现
class _BubblePopupAnimationState extends State<BubblePopupAnimation>
    with TickerProviderStateMixin {
  /// Show controller
  /// 显示动画控制器
  late final AnimationController _showController;

  /// Hide controller
  /// 隐藏动画控制器
  late final AnimationController _hideController;

  /// Fade animation used when showing
  /// 显示时使用的透明度动画
  late Animation<double> _fadeShowAnimation;

  /// Fade animation used when hiding
  /// 隐藏时使用的透明度动画
  late Animation<double> _fadeHideAnimation;

  /// Scale animation used when showing
  /// 显示时使用的缩放动画
  late Animation<double> _scaleShowAnimation;

  /// Scale animation used when hiding
  /// 隐藏时使用的缩放动画
  late Animation<double> _scaleHideAnimation;

  /// Whether current active phase is hiding
  /// 当前是否处于隐藏阶段
  bool _isHiding = false;

  /// Current fade progress
  /// 当前透明度进度值
  ///
  /// 注意：
  /// 该值用于 opacity，因此在使用时应限制在 0.0 ~ 1.0。
  double get currentValue {
    if (_isHiding) {
      return _fadeHideAnimation.value;
    }
    return _fadeShowAnimation.value;
  }

  /// Whether any animation is running
  /// 当前是否有任一动画控制器正在执行
  bool get isAnimating =>
      _showController.isAnimating || _hideController.isAnimating;

  /// Current scale progress
  /// 当前缩放进度值
  ///
  /// 注意：
  /// 该值允许大于 1.0，以保留 overshoot 效果。
  double get currentScaleValue {
    if (_isHiding) {
      return _scaleHideAnimation.value;
    }
    return _scaleShowAnimation.value;
  }

  @override
  void initState() {
    super.initState();

    _showController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _hideController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    /// 初始化静态动画值，避免首帧访问未初始化 animation.value
    final double initialValue = widget.controller.animation ? 1.0 : 0.0;
    _fadeShowAnimation = AlwaysStoppedAnimation(initialValue);
    _fadeHideAnimation = AlwaysStoppedAnimation(initialValue);
    _scaleShowAnimation = AlwaysStoppedAnimation(initialValue);
    _scaleHideAnimation = AlwaysStoppedAnimation(initialValue);

    _showController.addListener(_handleTick);
    _hideController.addListener(_handleTick);

    _showController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller._sync(
          value: 1,
          isAnimating: false,
          isVisible: true,
        );
        widget.onShow?.call();
      }
    });

    _hideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller._sync(
          value: 0,
          isAnimating: false,
          isVisible: false,
        );
        widget.onHide?.call();
      }
    });

    widget.controller._bind(this);
  }

  /// Handle animation tick
  /// 处理动画逐帧刷新
  ///
  /// controller 对外同步的是“可见进度”，因此这里仍限制在 0~1。
  void _handleTick() {
    if (!mounted) return;
    widget.controller._sync(
      value: currentValue.clamp(0.0, 1.0).toDouble(),
      isAnimating: isAnimating,
      isVisible: currentValue >= 1.0,
    );
    setState(() {});
  }

  /// Start show animation
  /// 执行显示动画
  ///
  /// 特点：
  /// - fade 从当前可见进度开始
  /// - scale 从当前缩放进度开始
  /// - scale 允许大于 1.0
  /// - 返回的 Future 会在动画真正完成后结束
  Future<void> show() async {
    final double startFade = currentValue.clamp(0.0, 1.0).toDouble();
    final double startScale = math.max(0, currentScaleValue);

    _hideController.stop();
    _showController.stop();

    _isHiding = false;

    _fadeShowAnimation = Tween<double>(
      begin: startFade,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _showController,
        curve: widget.fadeShowCurve,
      ),
    );

    _scaleShowAnimation = Tween<double>(
      begin: startScale,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _showController,
        curve: widget.scaleShowCurve,
      ),
    );

    _showController.value = 0.0;
    _handleTick();

    try {
      await _showController.forward().orCancel;
    } on TickerCanceled {
// ignore
    }
  }

  /// Start hide animation
  /// 执行隐藏动画
  ///
  /// 特点：
  /// - fade 从当前可见进度开始
  /// - scale 从当前缩放进度开始
  /// - scale 起点允许大于 1.0
  /// - 返回的 Future 会在动画真正完成后结束
  Future<void> hide() async {
    final double startFade = currentValue.clamp(0.0, 1.0).toDouble();
    final double startScale = math.max(0, currentScaleValue);

    _showController.stop();
    _hideController.stop();

    _isHiding = true;

    _fadeHideAnimation = Tween<double>(
      begin: startFade,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _hideController,
        curve: widget.fadeHideCurve,
      ),
    );

    _scaleHideAnimation = Tween<double>(
      begin: startScale,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _hideController,
        curve: widget.scaleHideCurve,
      ),
    );

    _hideController.value = 0.0;
    _handleTick();

    try {
      await _hideController.forward().orCancel;
    } on TickerCanceled {
// ignore
    }
  }

  /// Jump to fully hidden without playing hide animation.
  /// 无动画跳到完全隐藏态。
  void _jumpToHidden() {
    _showController.stop();
    _hideController.stop();
    _isHiding = true;
    _fadeHideAnimation = const AlwaysStoppedAnimation(0);
    _scaleHideAnimation = const AlwaysStoppedAnimation(0);
    _hideController.value = 0.0;
    widget.controller._sync(
      value: 0,
      isAnimating: false,
      isVisible: false,
    );
    if (mounted) {
      setState(() {});
    }
  }

  /// Map scale progress to actual scale value
  /// 将缩放进度映射为真实 scale 值
  ///
  /// 说明：
  /// - t = 0   -> beginScale
  /// - t = 1   -> 1.0
  /// - t > 1   -> 大于 1.0（保留 overshoot）
  double _mapScale(double t) {
    return widget.beginScale + (1 - widget.beginScale) * t;
  }

  @override
  void didUpdateWidget(covariant BubblePopupAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _showController.duration = widget.duration;
      _hideController.duration = widget.duration;
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._bind(null);
      widget.controller._bind(this);
    }
  }

  @override
  void dispose() {
    widget.controller._bind(null);
    _showController.removeListener(_handleTick);
    _hideController.removeListener(_handleTick);
    _showController.dispose();
    _hideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child ?? const SizedBox();

    /// opacity 必须限制在 0~1
    final double opacity = currentValue.clamp(0.0, 1.0).toDouble();

    /// scale 允许大于 1，以保留 overshoot
    final double scaleProgress = math.max(0, currentScaleValue);

    Widget animatedChild = Opacity(
      opacity: opacity,
      child: child,
    );

    if (widget.enableScale) {
      animatedChild = Transform.scale(
        scale: _mapScale(scaleProgress),
        alignment: widget.scaleAlignment,
        child: animatedChild,
      );
    }

    return Visibility(
      visible: opacity > 0.0,
      maintainSemantics: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainState: true,
      child: animatedChild,
    );
  }
}
