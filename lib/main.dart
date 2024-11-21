import 'package:ffbe_patcher/screens/main_screen.dart';
import 'package:ffbe_patcher/services/window_utils.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
  WindowUtils.setWindowSizeAndTitle(1200, 700, "FFBE Patcher");
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(
          useMaterial3: true,
        ),
        home: const MainScreen());
  }
}
