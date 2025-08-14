import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControlButtons extends StatefulWidget {
  const WindowControlButtons({super.key});

  @override
  State<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends State<WindowControlButtons>
    with WindowListener {
  bool _isMaximized = false;
  bool _isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  Future<void> _initWindowState() async {
    final maximized = await windowManager.isMaximized();
    final alwaysOnTop = await windowManager.isAlwaysOnTop();
    setState(() {
      _isMaximized = maximized;
      _isAlwaysOnTop = alwaysOnTop;
    });
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _toggleAlwaysOnTop() async {
    final newState = !_isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(newState);
    setState(() {
      _isAlwaysOnTop = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    Widget buildButton({
      required Widget icon,
      required String tooltip,
      required VoidCallback onPressed,
      Color? iconColor,
    }) {
      return IconButton(
        iconSize: 24,
        splashRadius: 24,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        color: iconColor ?? color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildButton(
          icon: Icon(
            _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
            size: 24,
            color: _isAlwaysOnTop ? theme.colorScheme.primary : color,
          ),
          tooltip: _isAlwaysOnTop ? '取消置顶' : '置顶',
          onPressed: _toggleAlwaysOnTop,
        ),
        const SizedBox(width: 2),
        buildButton(
          icon: const Icon(Icons.remove, size: 24),
          tooltip: '最小化',
          onPressed: () => windowManager.minimize(),
        ),
        const SizedBox(width: 2),
        buildButton(
          icon: Icon(
            _isMaximized ? Icons.filter_none : Icons.crop_din,
            size: 24,
          ),
          tooltip: _isMaximized ? '还原' : '最大化',
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        const SizedBox(width: 2),
        buildButton(
          icon: const Icon(Icons.close, size: 24),
          tooltip: '关闭',
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
