import 'package:flappy_popup_bubble/flappy_popup_bubble.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PopupMenuController _controller = PopupMenuController();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPopMenu(
              Container(
                decoration: BoxDecoration(
                    color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                width: 140,
                height: 50,
                alignment: Alignment.center,
                child: const Text(
                  "Long Press",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 200, 0, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _controller.hide();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8)),
                  width: 140,
                  height: 50,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  ///build pop menu
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
        return [
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
        ];
      },
      child: child,
    );
  }
}
