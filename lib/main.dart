import 'package:flutter/material.dart';
import 'package:flutter_lib_common/start/main.dart';
import 'package:flutter_agent_java/agent/ui.dart';

final visitRoutes = <String, WidgetBuilder>{'home': (BuildContext context, {arguments}) => const HomePage()};

const authRoutes = <String, WidgetBuilder>{};

void main() async {
  const appConfig = {};
  runApp(MyApp(visitRoutes, authRoutes, appConfig));
}
