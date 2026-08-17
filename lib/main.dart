import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_lab_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ColorHugApp());
}

class ColorHugApp extends StatelessWidget {
  const ColorHugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '颜色抱抱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7957D5),
          brightness: Brightness.light,
        ),
        fontFamilyFallback: const [
          'PingFang SC',
          'Hiragino Sans GB',
          'Arial Unicode MS',
        ],
      ),
      home: const ColorLabScreen(),
    );
  }
}
