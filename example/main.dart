import 'dart:math';

import 'package:flutter/material.dart';
import 'package:infinity_view/infinity_controller.dart';
import 'package:infinity_view/infinity_view.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(),
    darkTheme: ThemeData.dark(),
    home: InfinityExampleApp(),
  ));
}

class InfinityExampleApp extends StatelessWidget {
  InfinityExampleApp({super.key});

  final List<Color> colors = const [
    Colors.amber,
    Colors.blue,
    Colors.blueGrey,
    Colors.brown,
    Colors.cyan,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.green,
    Colors.indigo,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.lime,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.yellow
  ];

  final InfinityViewController _controller =
      InfinityViewController(onReady: (controller) {
    controller.setScale(0.25);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InfinityView(
        controller: _controller,
        shrinkWrap: true,
        shouldRotate: true,
        rotationSnappingTheshold: 5.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(
            10000,
            (index) => Positioned(
              top: Random().nextInt(100000).toDouble() - 50000,
              left: Random().nextInt(100000).toDouble() - 50000,
              child: Container(
                width: 150,
                height: 150,
                color: colors[Random().nextInt(colors.length)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
