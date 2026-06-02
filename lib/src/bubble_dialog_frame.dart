import 'package:flutter/material.dart';

/// BubbleDialogFrame 的控制器。
///
/// 作用：
/// - 从外部主动触发 BubbleDialogFrame 刷新界面
/// - 持有内部 State 的引用，用于调用 setState
class BubbleDialogFrameController {
  _BubbleDialogFrameState? _state;

  /// 绑定内部 State
  void _attach(_BubbleDialogFrameState state) {
    _state = state;
  }

  /// 解绑内部 State
  void _detach(_BubbleDialogFrameState state) {
    if (_state == state) {
      _state = null;
    }
  }

  /// 刷新 BubbleDialogFrame 对应的界面
  void refresh() {
    _state?._refresh();
  }
}

/// 一个用于监听“下一帧渲染完成”后执行回调的组件。
///
/// 功能：
/// - 在 initState 中注册下一帧回调
/// - 首帧渲染完成后执行 onNextFrame
/// - 支持通过 controller 主动刷新当前组件
///
/// 适用场景：
/// - Dialog / 页面内容首次渲染完成后执行逻辑
/// - 首帧结束后再弹提示、获取布局信息、触发动画等
/// - 需要从外部手动触发局部刷新
class BubbleDialogFrame extends StatefulWidget {
  /// 构建子树的方法。
  ///
  /// 每次调用 controller.refresh() 时，都会重新执行该 builder。
  final WidgetBuilder builder;

  /// 第一帧完成后的回调。
  final VoidCallback? onFirstFrame;

  /// 控制器，用于从外部触发刷新。
  final BubbleDialogFrameController? controller;

  const BubbleDialogFrame({
    super.key,
    required this.builder,
    this.onFirstFrame,
    this.controller,
  });

  @override
  State<BubbleDialogFrame> createState() => _BubbleDialogFrameState();
}

class _BubbleDialogFrameState extends State<BubbleDialogFrame> {
  @override
  void initState() {
    super.initState();

    ///将当前 State 绑定到 controller，便于外部调用 refresh。
    widget.controller?._attach(this);

    ///注册一个首帧结束后的回调。
    ///该回调会在当前 build/render 完成后执行。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onFirstFrame?.call();
    });
  }

  @override
  void didUpdateWidget(covariant BubbleDialogFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    ///如果 controller 发生变化，需要解绑旧 controller，
    ///并将当前 State 重新绑定到新的 controller。
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    ///组件销毁时解绑 controller，避免外部继续持有无效 State。
    widget.controller?._detach(this);
    super.dispose();
  }

  /// 内部刷新方法。
  ///
  /// 通过 controller.refresh() 间接调用，
  /// 本质上是执行 setState 触发当前组件重建。
  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
