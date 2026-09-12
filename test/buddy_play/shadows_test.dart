import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/shadows/shadows_model.dart';

void main() {
  test('投影随灯光与距离改变，重合和边界值保持有限', () {
    const light = Offset(.5, .96);
    final near = projectShadow(light, const Offset(.4, .75));
    final far = projectShadow(light, const Offset(.4, .53));
    expect(near.scale, greaterThan(far.scale));
    expect(
      projectShadow(const Offset(.3, .96), const Offset(.4, .64)).x,
      greaterThan(
        projectShadow(const Offset(.7, .96), const Offset(.4, .64)).x,
      ),
    );
    expect(projectShadow(light, light).scale.isFinite, true);
  });
  test('玩具与帽子可保存恢复', () {
    final m = ShadowsModel();
    m.hat();
    final d = m.toJson();
    m.preset();
    m.restore(d);
    expect(m.toys.last.hat, 1);
    expect(m.toys.length, 2);
  });
}
