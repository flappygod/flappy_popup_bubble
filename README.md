# flappy_popup_bubble

`flappy_popup_bubble` is a lightweight Flutter package to display a bubble-style popup menu near a target widget. It supports long-press or tap triggers, smart positioning, animation, and customizable background styles.

## Features

- Bubble popup with rounded corners and arrow indicator
- Trigger by long press, tap, or fully manual controller mode
- Overlay-based rendering with auto up/down placement
- Built-in menu item widget and separator support
- Optional hover overlay (e.g. blur mask)
- Customizable menu background via bubble options or decoration
- Boundary padding and offset controls for safer layout

## Installation

Add dependency in `pubspec.yaml`:

```yaml
dependencies:
  flappy_popup_bubble: ^1.1.5
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flappy_popup_bubble/flappy_popup_bubble.dart';
import 'package:flutter/material.dart';

class DemoMenu extends StatefulWidget {
  const DemoMenu({super.key});

  @override
  State<DemoMenu> createState() => _DemoMenuState();
}

class _DemoMenuState extends State<DemoMenu> {
  final BubblePopupMenuController _controller = BubblePopupMenuController();

  @override
  Widget build(BuildContext context) {
    return BubblePopupMenu(
      controller: _controller,
      triggerType: BubblePopupMenuTriggerType.onLongPress,
      align: BubblePopupMenuAlign.center,
      offsetSpace: 10,
      boundaryPadding: const EdgeInsets.all(12),
      background: const PopupMenuBackground.bubble(
        options: PopupBubbleOptions(
          bubbleColor: Colors.white,
          bubbleShadowColor: Colors.black38,
          bubbleShadowElevation: 5,
        ),
      ),
      menusBuilder: (context, controller) {
        return [
          BubblePopupMenuAction(
            text: 'Copy',
            icon: const Icon(Icons.copy, size: 16),
            onTap: controller.hide,
          ),
          BubblePopupMenuAction(
            text: 'Delete',
            icon: const Icon(Icons.delete, size: 16),
            onTap: controller.hide,
          ),
        ];
      },
      child: Container(
        width: 140,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Long Press', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
```

## Core APIs

### BubblePopupMenu

Main popup widget.

Key parameters:

- `controller`: external popup controller
- `child`: anchor/target widget
- `menusBuilder`: builds popup menu widgets
- `triggerType`: `onLongPress` (default), `onTap`, `none`
- `align`: popup horizontal alignment (`start`, `center`, `end`)
- `offsetSpace`: spacing between target and popup
- `offsetDx` / `offsetDy`: additional position offsets
- `boundaryPadding`: keep popup away from overlay edges
- `bubblePadding`: padding inside popup content area
- `background`: bubble background or custom decoration
- `hover`: optional full-screen overlay widget
- `translucent`: whether taps can pass through overlay
- `barrierDismissible`: close when tapping outside
- `showChildTop`: draw child copy in overlay top layer
- `bubbleAnimScaleEnable`, `bubbleAnimCurve`, `bubbleAnimDuration`: animation options
- `onPopupShow`, `onPopupHide`: popup lifecycle callbacks

Important:

- When `translucent == true`, `barrierDismissible` must be `false` (asserted in constructor).

### BubblePopupMenuController

Controller methods:

- `show()`: show popup
- `hide()`: hide popup
- `rebuild()`: rebuild menu and sub head
- `isShow()`: check whether popup is showing

### BubblePopupMenuAction

Built-in menu action widget for quick menu composition.

Common parameters:

- `text`, `textStyle`, `maxLines`
- `icon`
- `onTap`
- `width`, `height`
- `padding`
- `backgroundColor`
- `borderRadius`
- `enableSplash`

## Trigger Modes

- `BubblePopupMenuTriggerType.onLongPress`: show popup on long press
- `BubblePopupMenuTriggerType.onTap`: show popup on tap
- `BubblePopupMenuTriggerType.none`: manual mode with controller

## Background Customization

### Bubble style background

```dart
background: const PopupMenuBackground.bubble(
  options: PopupBubbleOptions(
    bubbleColor: Colors.white,
    bubbleRadius: BorderRadius.all(Radius.circular(10)),
    bubbleShadowColor: Colors.black38,
    bubbleShadowElevation: 5,
  ),
),
```

### Fully custom decoration

```dart
background: PopupMenuBackground.decoration(
  BoxDecoration(
    color: const Color(0xFF1F1F1F),
    borderRadius: BorderRadius.circular(12),
  ),
),
```

## Notes

- Ensure `menusBuilder` returns at least one menu item.
- Use `controller.rebuild()` after menu data changes.
- If you need blocking background interaction, use `translucent: false`.
- `showChildTop` can help keep anchor visual continuity while popup is shown.

## License

MIT
