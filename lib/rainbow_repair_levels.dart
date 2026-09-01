import 'package:flutter/material.dart';

@immutable
class RepairTask {
  const RepairTask({
    required this.title,
    required this.prompt,
    required this.colorName,
    required this.emoji,
  });

  final String title;
  final String prompt;
  final String colorName;
  final String emoji;
}

enum RepairSceneKind {
  garden,
  coast,
  forest,
  snow,
  desert,
  candy,
  farm,
  ocean,
  space,
  volcano,
  station,
  canyon,
  village,
  ice,
  castle,
  orchard,
  music,
  lake,
  factory,
  festival,
}

@immutable
class RepairMap {
  const RepairMap({
    required this.name,
    required this.emoji,
    required this.scene,
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.accent,
    required this.tasks,
  });

  final String name;
  final String emoji;
  final RepairSceneKind scene;
  final Color skyTop;
  final Color skyBottom;
  final Color ground;
  final Color accent;
  final List<RepairTask> tasks;
}

const repairStagesPerMap = 5;

const repairMaps = <RepairMap>[
  RepairMap(
    name: '晨光花园',
    emoji: '🌻',
    scene: RepairSceneKind.garden,
    skyTop: Color(0xFF9FE3FF),
    skyBottom: Color(0xFFF2FDFF),
    ground: Color(0xFF62CC72),
    accent: Color(0xFFFF6D88),
    tasks: [
      RepairTask(
        title: '叫醒太阳',
        prompt: '太阳公公需要一种明亮又温暖的颜色',
        colorName: '黄色',
        emoji: '☀️',
      ),
      RepairTask(
        title: '唤醒小河',
        prompt: '给小河穿上像晴朗天空一样的颜色',
        colorName: '蓝色',
        emoji: '💧',
      ),
      RepairTask(
        title: '种出草地',
        prompt: '小芽喜欢森林和叶子的颜色',
        colorName: '绿色',
        emoji: '🌱',
      ),
      RepairTask(
        title: '点亮花朵',
        prompt: '用热情又醒目的颜色叫醒小花吧',
        colorName: '红色',
        emoji: '🌷',
      ),
      RepairTask(
        title: '找回蝴蝶',
        prompt: '葡萄一样的颜色会让蝴蝶飞回来',
        colorName: '紫色',
        emoji: '🦋',
      ),
    ],
  ),
  RepairMap(
    name: '贝壳海湾',
    emoji: '🏝️',
    scene: RepairSceneKind.coast,
    skyTop: Color(0xFF8EDFFF),
    skyBottom: Color(0xFFFFF0B8),
    ground: Color(0xFFFFD878),
    accent: Color(0xFFFF6D64),
    tasks: [
      RepairTask(
        title: '晒金沙滩',
        prompt: '沙滩想变得像阳光一样金灿灿',
        colorName: '黄色',
        emoji: '🏖️',
      ),
      RepairTask(
        title: '装满大海',
        prompt: '海浪在寻找最清爽的天空颜色',
        colorName: '蓝色',
        emoji: '🌊',
      ),
      RepairTask(
        title: '扶起椰树',
        prompt: '椰子叶需要充满生命的颜色',
        colorName: '绿色',
        emoji: '🌴',
      ),
      RepairTask(
        title: '叫醒珊瑚',
        prompt: '珊瑚喜欢像小火苗一样的颜色',
        colorName: '红色',
        emoji: '🪸',
      ),
      RepairTask(
        title: '擦亮贝壳',
        prompt: '神秘贝壳藏着葡萄的颜色',
        colorName: '紫色',
        emoji: '🐚',
      ),
    ],
  ),
  RepairMap(
    name: '翡翠森林',
    emoji: '🌲',
    scene: RepairSceneKind.forest,
    skyTop: Color(0xFF75CEC1),
    skyBottom: Color(0xFFE5FFD2),
    ground: Color(0xFF3FA961),
    accent: Color(0xFF9B67E8),
    tasks: [
      RepairTask(
        title: '点亮萤火虫',
        prompt: '夜里的小灯笼要发出明亮的光',
        colorName: '黄色',
        emoji: '✨',
      ),
      RepairTask(
        title: '清澈溪流',
        prompt: '小溪想要雨滴一样的颜色',
        colorName: '蓝色',
        emoji: '🏞️',
      ),
      RepairTask(
        title: '唤醒大树',
        prompt: '树叶最熟悉的大自然颜色是什么',
        colorName: '绿色',
        emoji: '🌳',
      ),
      RepairTask(
        title: '染红浆果',
        prompt: '成熟浆果要穿上草莓色外衣',
        colorName: '红色',
        emoji: '🍓',
      ),
      RepairTask(
        title: '长出蘑菇',
        prompt: '魔法蘑菇喜欢葡萄般神秘的颜色',
        colorName: '紫色',
        emoji: '🍄',
      ),
    ],
  ),
  RepairMap(
    name: '雪花山谷',
    emoji: '🏔️',
    scene: RepairSceneKind.snow,
    skyTop: Color(0xFF9EC8FF),
    skyBottom: Color(0xFFF5FBFF),
    ground: Color(0xFFDCEEFF),
    accent: Color(0xFFFF536A),
    tasks: [
      RepairTask(
        title: '升起冬日暖阳',
        prompt: '冰雪里最需要暖暖的太阳颜色',
        colorName: '黄色',
        emoji: '🌤️',
      ),
      RepairTask(
        title: '染亮冰河',
        prompt: '冰河倒映着晴空，它需要什么颜色',
        colorName: '蓝色',
        emoji: '🧊',
      ),
      RepairTask(
        title: '唤醒松树',
        prompt: '不怕冷的松针保持着叶子的颜色',
        colorName: '绿色',
        emoji: '🌲',
      ),
      RepairTask(
        title: '温暖小木屋',
        prompt: '给屋顶涂上最热情醒目的颜色',
        colorName: '红色',
        emoji: '🏠',
      ),
      RepairTask(
        title: '点亮极光',
        prompt: '夜空魔法想要一抹神秘的葡萄色',
        colorName: '紫色',
        emoji: '🌌',
      ),
    ],
  ),
  RepairMap(
    name: '金色沙漠',
    emoji: '🐪',
    scene: RepairSceneKind.desert,
    skyTop: Color(0xFF75CAFF),
    skyBottom: Color(0xFFFFE1A2),
    ground: Color(0xFFE9B85A),
    accent: Color(0xFFEA5368),
    tasks: [
      RepairTask(
        title: '擦亮太阳盘',
        prompt: '沙漠上空少了一轮金灿灿的光',
        colorName: '黄色',
        emoji: '☀️',
      ),
      RepairTask(
        title: '注满绿洲',
        prompt: '珍贵的泉水想要雨滴的颜色',
        colorName: '蓝色',
        emoji: '💦',
      ),
      RepairTask(
        title: '救活仙人掌',
        prompt: '坚强的仙人掌需要叶子的颜色',
        colorName: '绿色',
        emoji: '🌵',
      ),
      RepairTask(
        title: '展开旅行帐篷',
        prompt: '远远就能看见的热情颜色是哪一种',
        colorName: '红色',
        emoji: '⛺',
      ),
      RepairTask(
        title: '发现紫水晶',
        prompt: '水晶里藏着葡萄一样的颜色',
        colorName: '紫色',
        emoji: '💎',
      ),
    ],
  ),
  RepairMap(
    name: '糖果小镇',
    emoji: '🍭',
    scene: RepairSceneKind.candy,
    skyTop: Color(0xFFFFC4E4),
    skyBottom: Color(0xFFFFF4C7),
    ground: Color(0xFF8EDB78),
    accent: Color(0xFFFF4F64),
    tasks: [
      RepairTask(
        title: '点亮糖果灯',
        prompt: '路灯要像柠檬糖一样闪亮',
        colorName: '黄色',
        emoji: '💡',
      ),
      RepairTask(
        title: '流出汽水河',
        prompt: '清凉汽水河喜欢天空的颜色',
        colorName: '蓝色',
        emoji: '🥤',
      ),
      RepairTask(
        title: '铺好薄荷路',
        prompt: '清新的薄荷糖是什么颜色',
        colorName: '绿色',
        emoji: '🍬',
      ),
      RepairTask(
        title: '盖好草莓屋',
        prompt: '草莓奶油屋需要果实的颜色',
        colorName: '红色',
        emoji: '🍓',
      ),
      RepairTask(
        title: '吹起葡萄气球',
        prompt: '气球要变成甜甜的葡萄颜色',
        colorName: '紫色',
        emoji: '🎈',
      ),
    ],
  ),
  RepairMap(
    name: '云朵牧场',
    emoji: '🐑',
    scene: RepairSceneKind.farm,
    skyTop: Color(0xFF8DD7FF),
    skyBottom: Color(0xFFF9FFFF),
    ground: Color(0xFF76C957),
    accent: Color(0xFFE64F62),
    tasks: [
      RepairTask(
        title: '叫醒小太阳',
        prompt: '牧场需要一束温暖明亮的晨光',
        colorName: '黄色',
        emoji: '🌞',
      ),
      RepairTask(
        title: '填满鸭子池',
        prompt: '池塘想穿上晴朗天空的颜色',
        colorName: '蓝色',
        emoji: '🦆',
      ),
      RepairTask(
        title: '铺开青草地',
        prompt: '小羊最爱的嫩草是什么颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '刷亮谷仓',
        prompt: '谷仓想换上醒目又热情的新衣',
        colorName: '红色',
        emoji: '🏠',
      ),
      RepairTask(
        title: '种下薰衣草',
        prompt: '香香的花田需要神秘葡萄色',
        colorName: '紫色',
        emoji: '🪻',
      ),
    ],
  ),
  RepairMap(
    name: '海底王国',
    emoji: '🐠',
    scene: RepairSceneKind.ocean,
    skyTop: Color(0xFF1A8FD0),
    skyBottom: Color(0xFF65DED4),
    ground: Color(0xFFE5C671),
    accent: Color(0xFFFF5C6F),
    tasks: [
      RepairTask(
        title: '找回珍珠光',
        prompt: '珍珠要发出像小太阳一样的光',
        colorName: '黄色',
        emoji: '🫧',
      ),
      RepairTask(
        title: '染蓝深海',
        prompt: '让整片海洋找回它熟悉的颜色',
        colorName: '蓝色',
        emoji: '🌊',
      ),
      RepairTask(
        title: '摇动海草',
        prompt: '海草也喜欢嫩叶的颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '唤醒红珊瑚',
        prompt: '热情的小珊瑚在等哪种颜色',
        colorName: '红色',
        emoji: '🪸',
      ),
      RepairTask(
        title: '打开章鱼城堡',
        prompt: '章鱼国王最爱葡萄般的颜色',
        colorName: '紫色',
        emoji: '🐙',
      ),
    ],
  ),
  RepairMap(
    name: '星空营地',
    emoji: '🚀',
    scene: RepairSceneKind.space,
    skyTop: Color(0xFF22255D),
    skyBottom: Color(0xFF594A91),
    ground: Color(0xFF52715C),
    accent: Color(0xFFFF5267),
    tasks: [
      RepairTask(
        title: '点亮小星星',
        prompt: '黑夜里什么颜色最像闪亮的星光',
        colorName: '黄色',
        emoji: '⭐',
      ),
      RepairTask(
        title: '修好蓝星球',
        prompt: '这颗星球想变成雨滴的颜色',
        colorName: '蓝色',
        emoji: '🌍',
      ),
      RepairTask(
        title: '种出太空草',
        prompt: '外星小芽也最喜欢叶子的颜色',
        colorName: '绿色',
        emoji: '🌱',
      ),
      RepairTask(
        title: '启动红火箭',
        prompt: '火箭需要醒目又有力量的颜色',
        colorName: '红色',
        emoji: '🚀',
      ),
      RepairTask(
        title: '旋转紫星云',
        prompt: '神秘星云藏着葡萄的颜色',
        colorName: '紫色',
        emoji: '🪐',
      ),
    ],
  ),
  RepairMap(
    name: '勇气火山岛',
    emoji: '🌋',
    scene: RepairSceneKind.volcano,
    skyTop: Color(0xFF35517B),
    skyBottom: Color(0xFFFFB172),
    ground: Color(0xFF5F744E),
    accent: Color(0xFFFF4F4F),
    tasks: [
      RepairTask(
        title: '召回火山光',
        prompt: '山顶需要像火焰一样勇敢的颜色',
        colorName: '红色',
        emoji: '🔥',
      ),
      RepairTask(
        title: '清理蓝湖',
        prompt: '火山脚下的湖水想映出天空',
        colorName: '蓝色',
        emoji: '💧',
      ),
      RepairTask(
        title: '长出勇气藤',
        prompt: '藤蔓需要大自然最有生命力的颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '点亮晶石洞',
        prompt: '洞里的魔法晶石是葡萄色的',
        colorName: '紫色',
        emoji: '💎',
      ),
      RepairTask(
        title: '撒下金火花',
        prompt: '最后让火花像星星一样明亮',
        colorName: '黄色',
        emoji: '✨',
      ),
    ],
  ),
  RepairMap(
    name: '樱花车站',
    emoji: '🚂',
    scene: RepairSceneKind.station,
    skyTop: Color(0xFF9BD9FF),
    skyBottom: Color(0xFFFFE4EE),
    ground: Color(0xFF74C976),
    accent: Color(0xFFED536A),
    tasks: [
      RepairTask(
        title: '点亮站台灯',
        prompt: '小火车需要一盏明亮的信号灯',
        colorName: '黄色',
        emoji: '🚦',
      ),
      RepairTask(
        title: '刷蓝候车亭',
        prompt: '候车亭想穿上晴空的颜色',
        colorName: '蓝色',
        emoji: '🚉',
      ),
      RepairTask(
        title: '长满铁路草',
        prompt: '铁轨旁的小草在等叶子的颜色',
        colorName: '绿色',
        emoji: '🌱',
      ),
      RepairTask(
        title: '开来红火车',
        prompt: '远处哪种颜色最醒目最好认',
        colorName: '红色',
        emoji: '🚂',
      ),
      RepairTask(
        title: '挂起紫藤花',
        prompt: '车站花架需要葡萄般的花朵',
        colorName: '紫色',
        emoji: '🪻',
      ),
    ],
  ),
  RepairMap(
    name: '恐龙峡谷',
    emoji: '🦕',
    scene: RepairSceneKind.canyon,
    skyTop: Color(0xFF79CCFF),
    skyBottom: Color(0xFFFFE0A3),
    ground: Color(0xFFB7784D),
    accent: Color(0xFFE15362),
    tasks: [
      RepairTask(
        title: '照亮古老山谷',
        prompt: '古老山谷需要太阳一样的光',
        colorName: '黄色',
        emoji: '☀️',
      ),
      RepairTask(
        title: '唤醒弯弯河',
        prompt: '恐龙喝水的小河是什么颜色',
        colorName: '蓝色',
        emoji: '🏞️',
      ),
      RepairTask(
        title: '长出大蕨叶',
        prompt: '史前蕨叶要找回自然的颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '发现红恐龙蛋',
        prompt: '这颗恐龙蛋像草莓一样醒目',
        colorName: '红色',
        emoji: '🥚',
      ),
      RepairTask(
        title: '打开水晶洞',
        prompt: '洞中水晶闪着神秘葡萄色',
        colorName: '紫色',
        emoji: '🔮',
      ),
    ],
  ),
  RepairMap(
    name: '蜂蜜村庄',
    emoji: '🐝',
    scene: RepairSceneKind.village,
    skyTop: Color(0xFFFFD96A),
    skyBottom: Color(0xFFFFF7CE),
    ground: Color(0xFF7ECB67),
    accent: Color(0xFFFF5C68),
    tasks: [
      RepairTask(
        title: '装满蜂蜜罐',
        prompt: '甜甜蜂蜜像哪一种明亮颜色',
        colorName: '黄色',
        emoji: '🍯',
      ),
      RepairTask(
        title: '清理村边小溪',
        prompt: '小溪想找回雨滴一样的颜色',
        colorName: '蓝色',
        emoji: '💦',
      ),
      RepairTask(
        title: '修好叶子屋顶',
        prompt: '叶子屋顶最适合自然的颜色',
        colorName: '绿色',
        emoji: '🍃',
      ),
      RepairTask(
        title: '打开草莓商店',
        prompt: '草莓招牌当然需要果实的颜色',
        colorName: '红色',
        emoji: '🍓',
      ),
      RepairTask(
        title: '种下紫花篱笆',
        prompt: '篱笆旁要开出葡萄色小花',
        colorName: '紫色',
        emoji: '🌸',
      ),
    ],
  ),
  RepairMap(
    name: '极光冰原',
    emoji: '🐧',
    scene: RepairSceneKind.ice,
    skyTop: Color(0xFF20356E),
    skyBottom: Color(0xFF64C9C6),
    ground: Color(0xFFD9F2FF),
    accent: Color(0xFF9B67E8),
    tasks: [
      RepairTask(
        title: '点亮北极星',
        prompt: '冰原上空需要一颗金亮的星星',
        colorName: '黄色',
        emoji: '⭐',
      ),
      RepairTask(
        title: '修复蓝冰川',
        prompt: '冰川里冻住了天空的颜色',
        colorName: '蓝色',
        emoji: '🧊',
      ),
      RepairTask(
        title: '唤醒苔藓地',
        prompt: '雪下的小生命是什么颜色',
        colorName: '绿色',
        emoji: '🌱',
      ),
      RepairTask(
        title: '找回红雪橇',
        prompt: '雪地里最容易看到哪种热情颜色',
        colorName: '红色',
        emoji: '🛷',
      ),
      RepairTask(
        title: '画出紫极光',
        prompt: '给极光添上最神秘梦幻的颜色',
        colorName: '紫色',
        emoji: '🌌',
      ),
    ],
  ),
  RepairMap(
    name: '云端城堡',
    emoji: '🏰',
    scene: RepairSceneKind.castle,
    skyTop: Color(0xFF86CCFF),
    skyBottom: Color(0xFFF3E9FF),
    ground: Color(0xFFE9F2FF),
    accent: Color(0xFF9B67E8),
    tasks: [
      RepairTask(
        title: '擦亮金皇冠',
        prompt: '国王的皇冠要像阳光一样闪耀',
        colorName: '黄色',
        emoji: '👑',
      ),
      RepairTask(
        title: '找回蓝天空',
        prompt: '云朵身后的晴空是什么颜色',
        colorName: '蓝色',
        emoji: '☁️',
      ),
      RepairTask(
        title: '爬满魔法藤',
        prompt: '城墙藤蔓需要叶子的颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '升起勇气旗',
        prompt: '城堡要挂起最醒目的热情旗帜',
        colorName: '红色',
        emoji: '🚩',
      ),
      RepairTask(
        title: '修复紫尖塔',
        prompt: '最高的塔顶想要葡萄色魔法',
        colorName: '紫色',
        emoji: '🏰',
      ),
    ],
  ),
  RepairMap(
    name: '水果乐园',
    emoji: '🍎',
    scene: RepairSceneKind.orchard,
    skyTop: Color(0xFF91D8FF),
    skyBottom: Color(0xFFFFF0B4),
    ground: Color(0xFF72C85F),
    accent: Color(0xFFFF4F64),
    tasks: [
      RepairTask(
        title: '挂上大香蕉',
        prompt: '香蕉成熟后像阳光一样明亮',
        colorName: '黄色',
        emoji: '🍌',
      ),
      RepairTask(
        title: '装满蓝莓池',
        prompt: '蓝莓池想要深深的天空色',
        colorName: '蓝色',
        emoji: '🫐',
      ),
      RepairTask(
        title: '长出西瓜藤',
        prompt: '西瓜藤要找回叶子的颜色',
        colorName: '绿色',
        emoji: '🍉',
      ),
      RepairTask(
        title: '转动苹果轮',
        prompt: '成熟苹果需要哪种热情颜色',
        colorName: '红色',
        emoji: '🍎',
      ),
      RepairTask(
        title: '挂满葡萄串',
        prompt: '甜葡萄当然要穿上自己的颜色',
        colorName: '紫色',
        emoji: '🍇',
      ),
    ],
  ),
  RepairMap(
    name: '音乐森林',
    emoji: '🎵',
    scene: RepairSceneKind.music,
    skyTop: Color(0xFF83D3C2),
    skyBottom: Color(0xFFE8FFD1),
    ground: Color(0xFF57B967),
    accent: Color(0xFF9B67E8),
    tasks: [
      RepairTask(
        title: '敲响金铃铛',
        prompt: '铃铛要闪着明亮的金色光芒',
        colorName: '黄色',
        emoji: '🔔',
      ),
      RepairTask(
        title: '弹奏蓝溪琴',
        prompt: '流动的琴弦像天空和雨滴',
        colorName: '蓝色',
        emoji: '🎶',
      ),
      RepairTask(
        title: '打开树叶舞台',
        prompt: '森林舞台需要大自然的颜色',
        colorName: '绿色',
        emoji: '🍃',
      ),
      RepairTask(
        title: '敲响大鼓',
        prompt: '大鼓想穿上热情有力的新衣',
        colorName: '红色',
        emoji: '🥁',
      ),
      RepairTask(
        title: '放飞魔法音符',
        prompt: '最后的音符是神秘葡萄色',
        colorName: '紫色',
        emoji: '🎵',
      ),
    ],
  ),
  RepairMap(
    name: '童话湖畔',
    emoji: '🦢',
    scene: RepairSceneKind.lake,
    skyTop: Color(0xFF89D4FF),
    skyBottom: Color(0xFFFFE9C7),
    ground: Color(0xFF63BB6E),
    accent: Color(0xFFEA5368),
    tasks: [
      RepairTask(
        title: '点亮湖边灯',
        prompt: '黄昏的小灯需要像星星一样发光',
        colorName: '黄色',
        emoji: '🏮',
      ),
      RepairTask(
        title: '唤醒镜子湖',
        prompt: '湖面要映出晴朗天空的颜色',
        colorName: '蓝色',
        emoji: '🦢',
      ),
      RepairTask(
        title: '长出荷叶',
        prompt: '圆圆荷叶需要自然的颜色',
        colorName: '绿色',
        emoji: '🪷',
      ),
      RepairTask(
        title: '修好红屋顶',
        prompt: '童话小屋想换醒目的草莓色屋顶',
        colorName: '红色',
        emoji: '🏡',
      ),
      RepairTask(
        title: '打开魔法小船',
        prompt: '小船帆上藏着葡萄色的魔法',
        colorName: '紫色',
        emoji: '⛵',
      ),
    ],
  ),
  RepairMap(
    name: '彩虹工厂',
    emoji: '⚙️',
    scene: RepairSceneKind.factory,
    skyTop: Color(0xFF7CC5E8),
    skyBottom: Color(0xFFEAF7FB),
    ground: Color(0xFF7E9C92),
    accent: Color(0xFFFF566D),
    tasks: [
      RepairTask(
        title: '接通能量灯',
        prompt: '工厂灯泡需要最明亮的颜色',
        colorName: '黄色',
        emoji: '💡',
      ),
      RepairTask(
        title: '修好蓝管道',
        prompt: '运送清水的管道要涂什么颜色',
        colorName: '蓝色',
        emoji: '🔧',
      ),
      RepairTask(
        title: '启动绿传送带',
        prompt: '安全通行需要大自然的颜色',
        colorName: '绿色',
        emoji: '⚙️',
      ),
      RepairTask(
        title: '按下红按钮',
        prompt: '最醒目的启动按钮是什么颜色',
        colorName: '红色',
        emoji: '🔴',
      ),
      RepairTask(
        title: '装满紫颜料罐',
        prompt: '最后一罐要装进葡萄色颜料',
        colorName: '紫色',
        emoji: '🪣',
      ),
    ],
  ),
  RepairMap(
    name: '彩虹庆典广场',
    emoji: '🎡',
    scene: RepairSceneKind.festival,
    skyTop: Color(0xFF7FCBFF),
    skyBottom: Color(0xFFFFE2F0),
    ground: Color(0xFF67C978),
    accent: Color(0xFFFF4F64),
    tasks: [
      RepairTask(
        title: '点亮庆典彩灯',
        prompt: '第一盏灯要像星星一样闪亮',
        colorName: '黄色',
        emoji: '✨',
      ),
      RepairTask(
        title: '开启音乐喷泉',
        prompt: '喷泉水花要找回天空的颜色',
        colorName: '蓝色',
        emoji: '⛲',
      ),
      RepairTask(
        title: '挂好绿叶花环',
        prompt: '花环上的叶子是什么颜色',
        colorName: '绿色',
        emoji: '🌿',
      ),
      RepairTask(
        title: '放飞红气球',
        prompt: '把最热情醒目的气球送上天空',
        colorName: '红色',
        emoji: '🎈',
      ),
      RepairTask(
        title: '点亮紫色烟花',
        prompt: '用神秘的葡萄色完成百关庆典',
        colorName: '紫色',
        emoji: '🎆',
      ),
    ],
  ),
];

const _creativeTaskOverrides = <int, RepairTask>{
  10: RepairTask(
    title: '点亮小萤火虫',
    prompt: '小萤火虫的肚子要发出温暖明亮的黄色光',
    colorName: '黄色',
    emoji: '🪲✨',
  ),
  6: RepairTask(
    title: '唤醒青色海浪',
    prompt: '浅浅的海浪像清亮玻璃一样，正在寻找青色',
    colorName: '青色',
    emoji: '🌊',
  ),
  8: RepairTask(
    title: '叫醒橙珊瑚',
    prompt: '珊瑚想穿上橘子一样暖暖的外衣',
    colorName: '橙色',
    emoji: '🪸',
  ),
  9: RepairTask(
    title: '擦亮粉贝壳',
    prompt: '这枚贝壳像樱花一样轻柔',
    colorName: '粉色',
    emoji: '🐚',
  ),
  11: RepairTask(
    title: '注满湖蓝溪流',
    prompt: '森林小溪倒映着清澈湖面的颜色',
    colorName: '湖蓝色',
    emoji: '🏞️',
  ),
  14: RepairTask(
    title: '长出棕色蘑菇',
    prompt: '小蘑菇想戴上像树干一样的帽子',
    colorName: '棕色',
    emoji: '🍄',
  ),
  15: RepairTask(
    title: '铺上白雪毯',
    prompt: '山谷需要一层像云朵一样洁白的雪',
    colorName: '白色',
    emoji: '❄️',
  ),
  16: RepairTask(
    title: '染亮青冰河',
    prompt: '透明冰河里藏着清清凉凉的青色',
    colorName: '青色',
    emoji: '🧊',
  ),
  21: RepairTask(
    title: '注满湖蓝绿洲',
    prompt: '珍贵的泉水要像明亮湖面一样清澈',
    colorName: '湖蓝色',
    emoji: '💦',
  ),
  23: RepairTask(
    title: '展开橙色帐篷',
    prompt: '旅行帐篷想穿上橘子一样温暖的颜色',
    colorName: '橙色',
    emoji: '⛺',
  ),
  26: RepairTask(
    title: '流出青色汽水河',
    prompt: '清凉汽水河像薄薄的冰块一样透亮',
    colorName: '青色',
    emoji: '🥤',
  ),
  27: RepairTask(
    title: '铺好薄荷糖路',
    prompt: '闻起来清清凉凉的薄荷糖是什么颜色',
    colorName: '薄荷色',
    emoji: '🍬',
  ),
  31: RepairTask(
    title: '填满湖蓝鸭子池',
    prompt: '小鸭子的池塘要像阳光下的湖水',
    colorName: '湖蓝色',
    emoji: '🦆',
  ),
  32: RepairTask(
    title: '铺开黄绿嫩草',
    prompt: '刚冒出来的嫩草带着一点黄色',
    colorName: '黄绿色',
    emoji: '🌿',
  ),
  35: RepairTask(
    title: '找回白珍珠',
    prompt: '海底珍珠要像云朵一样洁白明亮',
    colorName: '白色',
    emoji: '🫧',
  ),
  36: RepairTask(
    title: '染亮湖蓝深海',
    prompt: '阳光照进海里，变成了明亮的湖蓝色',
    colorName: '湖蓝色',
    emoji: '🌊',
  ),
  38: RepairTask(
    title: '唤醒橙色珊瑚',
    prompt: '这片珊瑚像橘子果肉一样暖暖的',
    colorName: '橙色',
    emoji: '🪸',
  ),
  41: RepairTask(
    title: '修好湖蓝星球',
    prompt: '从太空望去，这颗星球像发亮的湖水',
    colorName: '湖蓝色',
    emoji: '🌍',
  ),
  44: RepairTask(
    title: '找回深黑宇宙',
    prompt: '星光最清楚的夜空需要最深的颜色',
    colorName: '黑色',
    emoji: '🌌',
  ),
  46: RepairTask(
    title: '清理青色火山湖',
    prompt: '火山脚下的湖水清澈得透出青色',
    colorName: '青色',
    emoji: '💧',
  ),
  51: RepairTask(
    title: '刷亮湖蓝候车亭',
    prompt: '候车亭想穿上明亮湖水的颜色',
    colorName: '湖蓝色',
    emoji: '🚉',
  ),
  56: RepairTask(
    title: '唤醒湖蓝弯弯河',
    prompt: '恐龙喝水的小河映着亮亮的湖面',
    colorName: '湖蓝色',
    emoji: '🏞️',
  ),
  59: RepairTask(
    title: '打开靛蓝水晶洞',
    prompt: '洞中水晶闪着蓝色和紫色之间的光',
    colorName: '靛蓝色',
    emoji: '🔮',
  ),
  61: RepairTask(
    title: '清理青色村边溪',
    prompt: '小溪像清亮玻璃一样透出青色',
    colorName: '青色',
    emoji: '💦',
  ),
  64: RepairTask(
    title: '种下粉色花篱笆',
    prompt: '篱笆旁要开出像樱花一样轻柔的小花',
    colorName: '粉色',
    emoji: '🌸',
  ),
  66: RepairTask(
    title: '修复青色冰川',
    prompt: '透明冰川里冻住了清清凉凉的颜色',
    colorName: '青色',
    emoji: '🧊',
  ),
  69: RepairTask(
    title: '画出薄荷极光',
    prompt: '给极光添上一道清凉柔和的薄荷色',
    colorName: '薄荷色',
    emoji: '🌌',
  ),
  71: RepairTask(
    title: '找回湖蓝天空',
    prompt: '云朵身后的天空像明亮湖面一样',
    colorName: '湖蓝色',
    emoji: '☁️',
  ),
  74: RepairTask(
    title: '修复靛蓝尖塔',
    prompt: '最高的塔顶藏着蓝紫之间的神秘颜色',
    colorName: '靛蓝色',
    emoji: '🏰',
  ),
  76: RepairTask(
    title: '装满湖蓝莓果池',
    prompt: '蓝莓池闪着明亮又清澈的湖水色',
    colorName: '湖蓝色',
    emoji: '🫐',
  ),
  81: RepairTask(
    title: '弹奏青色溪流琴',
    prompt: '流动的琴弦像清清凉凉的玻璃',
    colorName: '青色',
    emoji: '🎶',
  ),
  83: RepairTask(
    title: '敲响棕色大鼓',
    prompt: '木头做的大鼓想找回树干的颜色',
    colorName: '棕色',
    emoji: '🥁',
  ),
  84: RepairTask(
    title: '放飞靛蓝音符',
    prompt: '最后的音符藏在蓝色和紫色之间',
    colorName: '靛蓝色',
    emoji: '🎵',
  ),
  86: RepairTask(
    title: '唤醒湖蓝镜子湖',
    prompt: '湖面要找回阳光下清澈闪亮的颜色',
    colorName: '湖蓝色',
    emoji: '🦢',
  ),
  91: RepairTask(
    title: '修好灰色金属管',
    prompt: '坚固的金属管道需要大象一样的颜色',
    colorName: '灰色',
    emoji: '🔧',
  ),
  94: RepairTask(
    title: '装满靛蓝颜料罐',
    prompt: '最后一罐要装进蓝紫之间的颜料',
    colorName: '靛蓝色',
    emoji: '🪣',
  ),
  96: RepairTask(
    title: '开启湖蓝音乐喷泉',
    prompt: '喷泉水花像阳光下的湖水一样闪亮',
    colorName: '湖蓝色',
    emoji: '⛲',
  ),
  99: RepairTask(
    title: '点亮粉色庆典烟花',
    prompt: '用像樱花一样快乐的颜色完成百关庆典',
    colorName: '粉色',
    emoji: '🎆',
  ),
};

const _repairOrderPatterns = <List<int>>[
  [0, 1, 2, 3, 4],
  [2, 0, 4, 1, 3],
  [4, 1, 3, 0, 2],
  [1, 3, 0, 4, 2],
  [3, 2, 4, 1, 0],
];

final List<List<RepairTask>> _tasksByMap = List<List<RepairTask>>.generate(
  repairMaps.length,
  (mapIndex) {
    final map = repairMaps[mapIndex];
    final order = _repairOrderPatterns[mapIndex % _repairOrderPatterns.length];
    return List<RepairTask>.unmodifiable(
      order.map((taskIndex) {
        final originalIndex = mapIndex * repairStagesPerMap + taskIndex;
        return _creativeTaskOverrides[originalIndex] ?? map.tasks[taskIndex];
      }),
    );
  },
  growable: false,
);

final List<RepairTask> repairTasks = List<RepairTask>.unmodifiable(
  _tasksByMap.expand((tasks) => tasks),
);

final int repairLevelTotal = repairTasks.length;

RepairMap repairMapForLevel(int levelIndex) {
  final safeIndex = levelIndex.clamp(0, repairLevelTotal - 1);
  return repairMaps[safeIndex ~/ repairStagesPerMap];
}

int repairMapIndexForLevel(int levelIndex) {
  final safeIndex = levelIndex.clamp(0, repairLevelTotal - 1);
  return safeIndex ~/ repairStagesPerMap;
}

int repairStageInMap(int completedLevels) =>
    completedLevels % repairStagesPerMap;

List<RepairTask> repairTasksForMap(int mapIndex) =>
    _tasksByMap[mapIndex.clamp(0, repairMaps.length - 1)];
