
import 'package:flutter/widgets.dart';

class ChatItem {
  String actor = '';
  int type = 1;
  String reasoningContent = '';
  String content = '';
  bool reasonEnd = false;
}

// 1. 定义一个自定义 Intent
class SubmitIntent extends Intent {
  const SubmitIntent();
}