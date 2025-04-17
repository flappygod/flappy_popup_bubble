TODO: This packages is used to show a bubble item or bubble popup menu easy.You can show the popup menu where you long touched smoothly.

## Features

1.Bubble items with border radius and a delta indicate。
2.Long press to show a bubble menu as a overlay.

## Getting started

add flappy_popup_bubble to your yaml.

## Usage

# Pop-up Menu Example

Below is an example of how to build a pop-up menu in Flutter using a custom `PopupMenu` widget:

```dart
/// Build pop-up menu
Widget _buildPopMenu(Widget child) {
  return PopupMenu(
      controller: _controller,
      translucent: true,
      barrierDismissible: true,
      bubbleOptions: const PopupBubbleOptions(
        bubbleShadowColor: Colors.black,
        bubbleShadowElevation: 5.0,
      ),
      menusBuilder: (context, controller) {
        return PopupMenuWithOptions(
          itemWidth: 120,
          itemHeight: 40,
          children: [
            PopupMenuBtn(
              text: "Function One",
              icon: const Icon(
                Icons.scale,
                color: Colors.white,
                size: 16,
              ),
              onTap: () {
                controller.hide();
              },
            ),
            PopupMenuBtn(
              text: "Function Two",
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
              onTap: () {
                controller.hide();
              },
            ),
          ],
        );
      },
      child: child,
    );
}



