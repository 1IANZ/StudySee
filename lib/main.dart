import 'dart:io';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:hbfu_alex/components/theme_manager.dart';
import 'package:hbfu_alex/pages/home/home.dart';
import 'package:hbfu_alex/pages/login/login.dart';
import 'package:hbfu_alex/src/rust/frb_generated.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: const Size(850, 620),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(850, 620),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.focus();
      await windowManager.show();
    });
  }

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeManager(), child: const App()),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final brightness = MediaQuery.of(context).platformBrightness;
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: themeManager.seedColor),
        ).useSystemChineseFont(brightness);

        return MaterialApp(
          title: 'StudySee',
          theme: theme,
          initialRoute: '/',
          routes: {
            '/': (context) => const Login(),
            '/home': (context) => const Home(),
          },
        );
      },
    );
  }
}
