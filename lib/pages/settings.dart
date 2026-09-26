import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:jicun/downloader.dart';
import 'package:jicun/shell_controller.dart';
import 'package:jicun/ui/glass.dart';
import 'package:jicun/ui/icons.dart';
import 'package:jicun/ui/motion.dart';
import 'package:jicun/ui/notifications.dart';
import 'package:jicun/ui/palette.dart';
import 'package:jicun/ui/popup.dart';
import 'package:jicun/ui/prefs.dart';
import 'package:jicun/ui/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.app});

  /// 二级页要改的是应用级状态(主题、底栏),所以直接持有根 State。
  final ShellController app;

  static const _options = <SettingsOption>[
    SettingsOption('主题与外观', '修改主题、显示效果'),
    SettingsOption('通知管理与下载', '通知管理与存储位置', icon: '通知管理'),
    SettingsOption('自动粘贴并解析', '剪贴板首条链接自动解析', icon: '通知管理'),
    // 检查更新是当场就办事的,没有下一级页面,所以不给箭头。
    SettingsOption('检查更新', '点击检查最新版本', showChevron: false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ShortBounceScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, kBoardHeaderTop, 20, 120),
      children: [
        const BoardHeader(title: '设置'),
        const SizedBox(height: 18),
        ..._options.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _options.length - 1 ? 0 : 12,
            ),
            child: SettingsOptionCard(
              option: entry.value,
              // 检查更新要打网络,慢的时候好几秒;转个圈至少让人知道点到了
              busy: entry.value.title == '检查更新' && app.checkingUpdate,
              onPressed: () => _handleOption(context, entry.value.title),
            ),
          ),
        ),
      ],
    );
  }

  void _handleOption(BuildContext context, String title) {
    if (title == '检查更新') {
      // 手动检查:没新版、被忽略过、检查失败都要给个回音 —— 用户是主动点的,
      // 什么都不弹会让人以为按钮坏了(见 checkForUpdate 的 manual 参数)。
      app.checkForUpdate(manual: true);
      return;
    }

    if (title == '主题与外观') {
      Navigator.of(context).push(
        SubPageRoute<void>(builder: (_) => ThemeAppearancePage(app: app)),
      );
      return;
    }

    if (title == '通知管理与下载') {
      Navigator.of(context).push(
        SubPageRoute<void>(
          builder: (_) => NotificationManagementPage(app: app),
        ),
      );
      return;
    }

    if (title == '自动粘贴并解析') {
      Navigator.of(context).push(
        SubPageRoute<void>(builder: (_) => AutoPastePage(app: app)),
      );
      return;
    }

    // 这个分支目前只有「使用帮助及反馈」到得了,但别处加一项没做二级页的设置就是它
    showInfo(context, title, '该设置项将在后续版本开放。');
  }
}

class SettingsOption {
  const SettingsOption(
    this.title,
    this.subtitle, {
    this.icon,
    this.showChevron = true,
  });

  final String title;
  final String subtitle;

  /// 右侧箭头。false 用于没有二级页、点一下就地生效的条目(检查更新)。
  final bool showChevron;

  /// 图标文件名(不含扩展名)。不填就拿标题当文件名。
  ///
  /// 单独留一个字段,是为了「改文案不用跟着改资源名」——图标是按旧标题命名的,
  /// 文案一改,靠标题拼路径就找不到图了。
  final String? icon;
}

class SettingsOptionCard extends StatelessWidget {
  const SettingsOptionCard({
    super.key,
    required this.option,
    required this.onPressed,
    this.busy = false,
  });

  final SettingsOption option;
  final VoidCallback onPressed;

  /// 这一项正在办事(目前只有「检查更新」)。为真时右侧显示转圈并挡住重复点击 ——
  /// 检查更新要打网络,慢的时候好几秒才有回音,不给任何动静就像按钮坏了。
  final bool busy;

  String _iconPath(BuildContext context) =>
      settingsIcon(context, '${option.icon ?? option.title}.svg');

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final secondary = settingsPalette(isDark).secondary;

    // 手写模糊面板。库的 GlassCard 无论走着色器路径、还是嵌套时的 vibrancy fill
    // 路径,都会在边界画一道高光:实测上沿 1 设备像素亮线(76 vs 内部 12),
    // 左沿 68 vs 内部 14,且 lightIntensity / fresnelStrength / useOwnLayer
    // 都关不掉。既然只要模糊,就自己拼,不再和库的着色器纠缠。
    final content = CupertinoButton(
      // 原来 18/18/16/18 + 50px 圆角块 = 86px 高,圆角块比右侧文字块还高,
      // 视觉上被图标块主导。收紧到 68px,让文字块重新成为主体。
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      onPressed: busy ? null : onPressed,
      pressedOpacity: 0.72,
      child: Row(
        children: [
          // 尺寸 20 而非资源的 24:图形在 24x24 画布里没有留白,
          // 按 24 渲染会顶满圆角块,20 才是正常呼吸感。
          GlassIconChip(isDark: isDark, asset: _iconPath(context)),
          const SizedBox(width: 14),
          Expanded(
            child: CardHeadline(
              isDark: isDark,
              title: option.title,
              subtitle: option.subtitle,
            ),
          ),
          if (busy) ...[
            const SizedBox(width: 8),
            // 用文字而不是转圈:转圈是**无限动画**,页面就再也 pumpAndSettle 不了
            // (用例里实测直接超时)。文字同样是"点到了、正在办"的回音,还不花帧。
            Text(
              '检查中…',
              style: TextStyle(
                color: secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (option.showChevron) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_forward, color: secondary, size: 17),
          ],
        ],
      ),
    );

    return GlassPanel(isDark: isDark, child: content);
  }
}

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key, required this.app});

  /// 这两个开关下载流程要用,所以和「主题与外观」一样直接持有根 State。
  final ShellController app;

  @override
  State<NotificationManagementPage> createState() =>
      NotificationManagementPageState();
}

class NotificationManagementPageState
    extends State<NotificationManagementPage> {
  bool _isSending = false;

  ShellController get app => widget.app;

  /// 要一次通知权限。和首次授权卡走同一个实现,免得两处判断分家。
  Future<bool> _requestPermission() => requestNotificationPermission();

  /// 拨一个下载通知开关。
  ///
  /// 打开前先要系统通知权限:没权限就别把开关点亮 —— 点亮了却弹不出通知,
  /// 用户只会以为是我们没做。关闭不需要权限,直接写。
  Future<void> _setNotify({required bool onDone, required bool value}) async {
    if (value) {
      final granted = await _requestPermission();
      if (!mounted) return;
      if (!granted) {
        showInfo(
          context,
          '通知权限未开启',
          '请在系统设置中允许懒得去发送通知。',
          icon: settingsIcon(context, '通知管理.svg'),
        );
        return;
      }
    }
    app.applySetting(() {
      if (onDone) {
        app.notifyDownloadDone = value;
      } else {
        app.notifyDownloadFailed = value;
      }
    });
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSending = true);
    try {
      final granted = await _requestPermission();
      if (!mounted) return;
      if (!granted) {
        showInfo(
          context,
          '通知权限未开启',
          '请在系统设置中允许懒得去发送通知。',
          icon: settingsIcon(context, '通知管理.svg'),
        );
        return;
      }
      final ready = notificationsReady;
      if (ready != null) await ready;
      await notifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        title: '懒得去通知测试',
        body: '通知功能运行正常。',
        notificationDetails: kNotificationDetails,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return SubPage(
      title: '通知管理与下载',
      child: GoogleSurface(
        brightness: isDark ? Brightness.dark : Brightness.light,
        child: SafeArea(
          child: ListView(
            physics: const ShortBounceScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              GlassPanel(
                isDark: isDark,
                child: GoogleSwitchRow(
                  isDark: isDark,
                  title: '下载完成通知',
                  subtitle: '下载成功后,在系统状态栏提醒一声',
                  value: app.notifyDownloadDone,
                  onChanged: (value) => _setNotify(onDone: true, value: value),
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                isDark: isDark,
                child: GoogleSwitchRow(
                  isDark: isDark,
                  title: '下载失败通知',
                  subtitle: '下载中断或出错时提醒,免得白等',
                  value: app.notifyDownloadFailed,
                  onChanged: (value) => _setNotify(onDone: false, value: value),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _isSending ? null : _sendTestNotification,
                child: Text(_isSending ? '发送中…' : '测试通知'),
              ),
              const SizedBox(height: 24),
              StorageLocationCard(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「设置 → 自动粘贴并解析」的二级页。
///
/// 只有一张开关卡,样式与「通知管理与下载」页同一套
/// (GlassPanel + GoogleSwitchRow,同一张顶栏图):打开后,每次进入 APP
/// 都会把剪贴板首条链接自动填进输入栏并解析(见 `_maybeAutoPasteParse`)。
class AutoPastePage extends StatelessWidget {
  const AutoPastePage({super.key, required this.app});

  final ShellController app;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return SubPage(
      title: '自动粘贴并解析',
      child: GoogleSurface(
        brightness: isDark ? Brightness.dark : Brightness.light,
        child: SafeArea(
          child: ListView(
            physics: const ShortBounceScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              GlassPanel(
                isDark: isDark,
                child: GoogleSwitchRow(
                  isDark: isDark,
                  title: '进入APP自动粘贴并解析首条链接',
                  subtitle: '从其他平台复制链接后,打开即自动解析',
                  value: app.autoPasteParse,
                  onChanged: (value) => app.applySetting(
                    () => app.autoPasteParse = value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「存储保存位置」卡。
///
/// 直接摊开,不做伸缩:只有三行,而且用户来这儿就是想知道文件去哪了,不该再点一下。
/// 路径由 Android 侧的媒体库归档决定(见 MainActivity 的 `ROOT` 与 `kindOf`),
/// 这里只做告知,不提供修改 —— 换目录得同时改 Kotlin 那套 MediaStore 映射、
/// [MediaKind] 里的展示路径和这张卡,不是切个开关的事。
///
/// 两边必须一字不差:这里写 Movies/Jicun/Video,那边就得真存到那儿,否则这页就是
/// 在骗用户(上一版就是:显示 Download/Jicun/*,实际存 Movies/JICUN、Pictures/Pictures)。
class StorageLocationCard extends StatelessWidget {
  const StorageLocationCard({super.key, required this.isDark});

  final bool isDark;

  static const _rows = <(String, String)>[
    ('视频 / 实况', 'Movies/Jicun/Video'),
    ('图片', 'Pictures/Jicun/Picture'),
    ('音频', 'Music/Jicun/Music'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: GoogleCardTitle(isDark: isDark, text: '存储保存位置'),
          ),
          for (final (label, path) in _rows)
            GoogleValueRow(isDark: isDark, label: label, value: path),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ThemeModeCard extends StatefulWidget {
  const ThemeModeCard({super.key, required this.app, required this.isDark});

  final ShellController app;
  final bool isDark;

  @override
  State<ThemeModeCard> createState() => ThemeModeCardState();
}

class ThemeModeCardState extends State<ThemeModeCard> {
  static const List<(AppThemeMode, String)> _options = [
    (AppThemeMode.system, '跟随系统'),
    (AppThemeMode.light, '浅色'),
    (AppThemeMode.dark, '深色'),
  ];

  bool _expanded = false;

  String get _currentLabel =>
      _options.firstWhere((o) => o.$1 == widget.app.themeMode).$2;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final secondary = settingsPalette(isDark).secondary;

    return GlassPanel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlainTap(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 14, 22),
              child: Row(
                children: [
                  GoogleCardTitle(isDark: isDark, text: '系统主题'),
                  const Spacer(),
                  Text(
                    _currentLabel,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RevealChevron(expanded: _expanded, color: secondary),
                ],
              ),
            ),
          ),
          Reveal(
            expanded: _expanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: RadioGroup<AppThemeMode>(
                groupValue: widget.app.themeMode,
                onChanged: (mode) {
                  if (mode == null) return;
                  widget.app.applySetting(() => widget.app.themeMode = mode);
                  widget.app.syncNightModeToNative(mode);
                  // 选完缩回去,回到收起卡片
                  setState(() => _expanded = false);
                },
                child: Column(
                  children: [
                    for (final (mode, label) in _options)
                      GoogleChoiceRow<AppThemeMode>(
                        isDark: isDark,
                        value: mode,
                        label: label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// 「设置 → 主题与外观」的二级页
class ThemeAppearancePage extends StatelessWidget {
  const ThemeAppearancePage({super.key, required this.app});

  final ShellController app;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return SubPage(
      title: '主题与外观',
      child: GoogleSurface(
        brightness: isDark ? Brightness.dark : Brightness.light,
        child: SafeArea(
          child: ListView(
            physics: const ShortBounceScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              ThemeModeCard(app: app, isDark: isDark),
              const SizedBox(height: 16),
              BarAppearanceCard(app: app, isDark: isDark),
              const SizedBox(height: 16),
              UiScaleCard(app: app, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「底栏外观样式」卡:两个开关都只作用于底栏,所以合成一张。
///
/// 展开/收起与「系统主题」卡同一套(收起时只留一行标题 + 当前样式 + 箭头,
/// 点开向下滑出,见 [Reveal])。
class BarAppearanceCard extends StatefulWidget {
  const BarAppearanceCard({super.key, required this.app, required this.isDark});

  final ShellController app;
  final bool isDark;

  @override
  State<BarAppearanceCard> createState() => BarAppearanceCardState();
}

class BarAppearanceCardState extends State<BarAppearanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final app = widget.app;
    final secondary = settingsPalette(isDark).secondary;

    return GlassPanel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlainTap(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 14, 22),
              child: Row(
                children: [
                  GoogleCardTitle(isDark: isDark, text: '底栏外观样式'),
                  const Spacer(),
                  Text(
                    // 收起时这一行就是这张卡的「当前值」:和系统主题卡同一位置
                    app.glassBottomBar ? '液态玻璃' : '渐变按钮',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RevealChevron(expanded: _expanded, color: secondary),
                ],
              ),
            ),
          ),
          Reveal(
            expanded: _expanded,
            child: Column(
              children: [
                GoogleSwitchRow(
                  isDark: isDark,
                  title: '底栏文字标识隐藏',
                  subtitle: '开启后隐藏底栏的解析、历史、设置文字',
                  value: app.hideTabLabels,
                  onChanged: (v) =>
                      app.applySetting(() => app.hideTabLabels = v),
                ),
                GoogleSwitchRow(
                  isDark: isDark,
                  title: 'Apple 底栏液态玻璃风格',
                  subtitle: '关闭后底栏取消液态玻璃,改用渐变按钮样式',
                  value: app.glassBottomBar,
                  onChanged: (v) =>
                      app.applySetting(() => app.glassBottomBar = v),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「界面缩放大小」卡。
///
/// 收起/展开与系统主题、底栏外观样式同一套;拖动中的值只存在这张卡自己的 State 里:
/// 每帧只重建这一小块,不惊动整棵树,所以滑杆跟手。松手(onChangeEnd)才把值交给
/// 根 State 去真正缩放并落盘 —— 缩放会让整屏按新尺寸重新布局,每帧都做必然拖不动。
class UiScaleCard extends StatefulWidget {
  const UiScaleCard({super.key, required this.app, required this.isDark});

  static const double min = 0.8;
  static const double max = 1.3;

  final ShellController app;
  final bool isDark;

  @override
  State<UiScaleCard> createState() => UiScaleCardState();
}

class UiScaleCardState extends State<UiScaleCard> {
  late double _draft = widget.app.uiScale;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final secondary = settingsPalette(isDark).secondary;
    return GlassPanel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlainTap(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 14, 22),
              child: Row(
                children: [
                  GoogleCardTitle(isDark: isDark, text: '界面缩放大小'),
                  const Spacer(),
                  Text(
                    '${(_draft * 100).round()}%',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RevealChevron(expanded: _expanded, color: secondary),
                ],
              ),
            ),
          ),
          Reveal(
            expanded: _expanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    // 拖动时不画把手的灰色光晕:压在玻璃卡上就是一团阴影
                    data: SliderTheme.of(context)
                        .copyWith(overlayShape: SliderComponentShape.noOverlay),
                    child: Slider(
                      value: _draft,
                      min: UiScaleCard.min,
                      max: UiScaleCard.max,
                      // 不设 divisions:刻度会让把手一格一格跳,手感发涩、不跟手
                      label: '${(_draft * 100).round()}%',
                      onChanged: (v) => setState(() => _draft = v),
                      onChangeEnd: (v) => widget.app.applySetting(
                        () => widget.app.uiScale = v,
                      ),
                    ),
                  ),
                  Text(
                    '拖动调整,松手应用',
                    style: TextStyle(color: secondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

