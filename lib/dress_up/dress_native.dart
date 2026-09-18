import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DressNativeController {
  DressNativeController(int id)
    : _channel = MethodChannel('colorhug/dress3d/$id');
  final MethodChannel _channel;
  bool _closed = false;
  Future<T?> call<T>(String name, [Object? args]) async {
    if (_closed) return null;
    return _channel.invokeMethod<T>(name, args);
  }

  Future<void> dispose() async {
    if (_closed) return;
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException {
      /* Native view already removed. */
    } on MissingPluginException {
      /* Engine is shutting down. */
    }
    _closed = true;
  }
}

class DressNativeStage extends StatelessWidget {
  const DressNativeStage({
    super.key,
    required this.values,
    required this.onReady,
  });
  final Map<String, Object> values;
  final ValueChanged<DressNativeController> onReady;
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return AppKitView(
        viewType: 'colorhug/dress3d',
        creationParams: values,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) => onReady(DressNativeController(id)),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'colorhug/dress3d',
        creationParams: values,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) => onReady(DressNativeController(id)),
      );
    }
    return const Center(child: Text('请在 iPhone、iPad 或 Mac 上打开立体衣帽间'));
  }
}
