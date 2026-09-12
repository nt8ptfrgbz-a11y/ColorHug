// Real native-app smoke entrypoint. Keep the child's journal untouched.
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:color_hug/main.dart';
import 'package:color_hug/island_progress.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(ColorHugApp(progress: IslandProgress()));
}
