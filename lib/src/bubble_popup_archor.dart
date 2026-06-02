import 'package:flutter/material.dart';

/// [BubblePopupAnchor] 的 rect 读取器。
///
/// 作用：
/// - 由 [BubblePopupAnchor] 在 mount / dispose 时绑定、解绑 [BuildContext]
/// - 供 [BubblePopupMenu] 等持有方在任意时刻调用 [globalRect] 读取列表侧 anchor 的全局位置与尺寸
///
/// 与 GlobalKey 的区别：
/// - 仅用于测量，不参与 Element reparent
/// - 无 GlobalKey 注册表开销，持有方通过 scope 直接访问 context
///
/// 解绑时校验 owner，避免旧 State dispose 误清新 State 已绑定的 context。
class BubblePopupAnchorScope {
  _BubblePopupAnchorState? _state;

  /// 绑定 anchor State（由 [BubblePopupAnchor] 内部调用）
  void _attach(_BubblePopupAnchorState state) {
    _state = state;
  }

  /// 解绑 anchor State；仅当 [state] 仍为当前 owner 时清空（由 [BubblePopupAnchor] 内部调用）
  void _detach(_BubblePopupAnchorState state) {
    if (_state == state) {
      _state = null;
    }
  }

  /// 读取当前 anchor slot 在屏幕坐标系下的矩形。
  ///
  /// 返回 null 表示：尚未 attach、State 已 dispose、尚未 layout（无 size）或 renderObject 不是 [RenderBox]。
  /// 测量的是 [BubblePopupAnchor.child] 根节点的布局结果（含 showChildTop 时的占位 [SizedBox]）。
  Rect? globalRect() {
    final _BubblePopupAnchorState? state = _state;
    if (state == null || !state.mounted) {
      return null;
    }
    final BuildContext context = state.context;
    final Object? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final Offset offset = renderObject.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderObject.size.width,
      renderObject.size.height,
    );
  }
}

/// 列表侧 child 的 anchor 包裹层，用于弹层对齐时读取全局 rect。
///
/// 功能：
/// - 在生命周期内将 State 注册到 [BubblePopupAnchorScope]
/// - build 仅透传 [child]，不改动布局与视觉
///
/// 适用场景（[BubblePopupMenu]）：
/// - 弹层打开前：测量真实 child 的位置，用于 popup 定位与平移动画
/// - showChildTop 弹层展示中：测量列表侧占位 slot，用于滚动 / hide 动画时刷新锚点
///
/// 用法：
/// ```dart
/// final scope = BubblePopupAnchorScope();
/// BubblePopupAnchor(
///   scope: scope,
///   child: childOrPlaceholder,
/// );
/// // 需要时
/// final Rect? rect = scope.globalRect();
/// ```
class BubblePopupAnchor extends StatefulWidget {
  const BubblePopupAnchor({
    super.key,
    required this.scope,
    required this.child,
  });

  /// rect 读取器，通常由父级 [State] 持有并在 show / hide / rebuild 时调用 [BubblePopupAnchorScope.globalRect]
  final BubblePopupAnchorScope scope;

  /// 列表侧 slot 内容（真实 child 或同尺寸占位）
  final Widget child;

  @override
  State<BubblePopupAnchor> createState() => _BubblePopupAnchorState();
}

class _BubblePopupAnchorState extends State<BubblePopupAnchor> {
  @override
  void initState() {
    super.initState();
    widget.scope._attach(this);
  }

  @override
  void didUpdateWidget(covariant BubblePopupAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      oldWidget.scope._detach(this);
      widget.scope._attach(this);
    }
  }

  @override
  void dispose() {
    widget.scope._detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
