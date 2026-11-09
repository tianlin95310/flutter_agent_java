import 'package:flutter/material.dart';
import 'package:flutter_agent_java/agent/view/ui.dart';
import 'package:flutter_lib_common/start/main-riverpod.dart';
// 顶层变量是懒加载的（Lazily Initialized）。 Dart 语言规范规定，顶层变量和静态变量只有在第一次被读取时，其初始化表达式才会执行。
final visitRoutes = <String, WidgetBuilder>{'home': (BuildContext context, {arguments}) => const HomePage()};

final authRoutes = <String, WidgetBuilder>{};

void main() async {
  const appConfig = {};
  runApp(MyAppRiverPod(visitRoutes, authRoutes, appConfig));
}
