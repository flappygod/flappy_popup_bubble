# flappy_popup_bubble

`flappy_popup_bubble` is a lightweight Flutter package to display a bubble-style popup menu near a target widget. It supports long-press or tap triggers, smart positioning, enter/exit animations, and customizable background styles.

## Features

- Bubble popup with rounded corners and arrow indicator
- Enter/exit animations (fade + optional scale, child translate)
- Trigger by long press, tap, or fully manual controller mode
- Overlay-based rendering with auto or forced up/down placement
- Generic popup data via `BubblePopupMenu<T>` and `controller.show(data: ...)`
- Built-in menu item widget and separator support
- Optional header area (`headerBuilder`)
- Optional hover overlay (e.g. blur mask)
- Customizable menu background via bubble options or decoration
- Boundary padding for safer layout
- Standalone `BubblePopupAnimation` widget for custom popups

## Installation

Add dependency in `pubspec.yaml`:

```yaml
dependencies:
  flappy_popup_bubble: ^2.0.0
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
      direction: BubblePopupMenuDirection.auto,
      boundaryPadding: const EdgeInsets.all(12),
      background: const PopupMenuBackground.bubble(
        options: PopupBubbleOptions(
          bubbleColor: Colors.white,
          bubbleShadowColor: Colors.black38,
          bubbleShadowElevation: 5,
        ),
      ),
      menusBuilder: (context, controller, data) {
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

Main popup widget. Supports an optional generic type `T` for popup-associated data.

Key parameters:

- `controller`: external popup controller (`BubblePopupMenuController<T>`)
- `child`: anchor/target widget
- `menusBuilder`: builds popup menu widgets; signature `(context, controller, data)`
- `headerBuilder`: optional header above the menu; same signature as `menusBuilder`
- `triggerType`: `onLongPress` (default), `onTap`, `none`
- `align`: popup horizontal alignment (`start`, `center`, `end`)
- `direction`: popup placement (`auto`, `up`, `down`)
- `menuPadding` / `headerPadding`: padding around menu and header in overlay
- `boundaryPadding`: keep popup away from overlay edges
- `bubblePadding`: padding inside popup content area
- `background`: bubble background or custom decoration
- `hover`: optional full-screen overlay widget
- `translucent`: whether taps can pass through overlay
- `barrierDismissible`: close when tapping outside
- `showChildTop`: draw child copy in overlay top layer
- `bubbleAnimScaleEnable`, `bubbleAnimCurve`, `bubbleAnimDuration`: popup scale/fade animation
- `childTranslateCurve`: curve for child translate animation while popup is open
- `shouldHandlePopup`: filter which menu instance handles events when sharing one controller (e.g. in lists)
- `onPopupShow`, `onPopupHide`: popup lifecycle callbacks

Important:

- When `translucent == true`, `barrierDismissible` must be `false` (asserted in constructor).

### BubblePopupMenuController

Controller methods:

- `show({T? data})`: show popup and optionally attach data
- `hide({bool animated = true})`: hide popup; set `animated: false` to remove immediately
- `rebuild()`: rebuild menu and header
- `clearData()`: clear attached data
- `isShow()`: check whether popup is showing
- `data`: read current popup data

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

### BubblePopupAnimation

Reusable fade/scale animation wrapper, usable outside `BubblePopupMenu`.

- `BubblePopupAnimationController`: call `show()` / `hide()` to drive animation
- `enableScale`, `beginScale`, `scaleAlignment`, `curve`, `duration`

## Trigger Modes

- `BubblePopupMenuTriggerType.onLongPress`: show popup on long press
- `BubblePopupMenuTriggerType.onTap`: show popup on tap
- `BubblePopupMenuTriggerType.none`: manual mode with controller

## Popup Data (Generic)

Pass context into the popup when opening:

```dart
final BubblePopupMenuController<Item> controller = BubblePopupMenuController();

BubblePopupMenu<Item>(
  controller: controller,
  menusBuilder: (context, controller, data) {
    final item = data;
    // build menu based on item
    return [...];
  },
  child: ...,
);

// later
controller.show(data: selectedItem);
```

For list items sharing one controller, use `shouldHandlePopup`:

```dart
shouldHandlePopup: (data) => data?.id == widget.item.id,
```

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

## Migration from 1.x

- Bump dependency to `^2.0.0`.
- `menusBuilder` now has a third parameter `T? data`; update callbacks to `(context, controller, data)`.
- `offsetSpace`, `offsetDx`, and `offsetDy` were removed; use `menuPadding`, `boundaryPadding`, and layout around `child` instead.
- `controller.hide()` plays exit animation by default; use `hide(animated: false)` for instant dismiss.
- Popup show/hide uses built-in `BubblePopupAnimation`; tune via `bubbleAnim*` and `childTranslateCurve`.

## Notes

- Ensure `menusBuilder` returns at least one menu item.
- Use `controller.rebuild()` after menu data changes.
- If you need blocking background interaction, use `translucent: false`.
- `showChildTop` can help keep anchor visual continuity while popup is shown.

## License

MIT
