import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ShanhaiNativeController {
  ShanhaiNativeController(int id)
    : _channel = MethodChannel('colorhug/shanhai3d/$id');
  final MethodChannel _channel;
  bool _closed = false;
  Future<T?> call<T>(String method, [Object? arguments]) async {
    if (_closed) return null;
    return _channel.invokeMethod<T>(method, arguments);
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException {
      /* already closed */
    } on MissingPluginException {
      /* engine detached */
    }
  }
}

class ShanhaiNativeStage extends StatelessWidget {
  const ShanhaiNativeStage({
    super.key,
    required this.values,
    required this.onReady,
  });
  final Map<String, Object> values;
  final ValueChanged<ShanhaiNativeController> onReady;
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return AppKitView(
        viewType: 'colorhug/shanhai3d',
        creationParams: values,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) => onReady(ShanhaiNativeController(id)),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'colorhug/shanhai3d',
        creationParams: values,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) => onReady(ShanhaiNativeController(id)),
      );
    }
    return const Center(
      child: Text(
        '在 Mac、iPhone 或 iPad 上开启山海之旅',
        style: TextStyle(color: Color(0xFFE9D8AD)),
      ),
    );
  }
}
