import 'dart:async';

import 'package:flutter_agent_java/agent/model/main.dart';
import 'package:flutter_lib_common/main.dart';

class OpenAIVM extends AsyncNotifier<Stream<String>?> {
  @override
  Future<Stream<String>>? build() {
    return null;
  }

  Stream<String> chat(dynamic request, {Future? abortTrigger}) {
    final openai = ref.read(openAIHttpProvider);
    final response = openai.chat(request, abortTrigger: abortTrigger);
    print('response = ');
    print(response);
    return response;
  }

  void listenBody(String line, StringBuffer dataBuffer, {Function? flushEvent, StreamSubscription? streamSubscription}) {
    // print('line = ');
    // print(line);
    // 空行代表一个 SSE 事件结束
    if (line.isEmpty) {
      // 通常在flushEvent处理积累的 dataBuffer
      flushEvent?.call();
      return;
    }
    // 忽略注释行（以 : 开头）
    if (line.startsWith(':')) return;

    // 解析 "data: xxx" 这样的字段
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return; // 无冒号的行，根据规范可忽略

    final field = line.substring(0, colonIndex);
    final value = (colonIndex + 1 < line.length && line[colonIndex + 1] == ' ')
        ? line.substring(colonIndex + 2)
        : line.substring(colonIndex + 1);

    if (field == 'data') {
      // 当前事件流结束
      if (value == '[DONE]') {
        streamSubscription?.cancel();
        return;
      }
      // 将 data 追加到当前事件的缓冲区
      dataBuffer.write(value);
    }
  }
}

final openaiVmProvider = AsyncNotifierProvider<OpenAIVM, Stream<String>?>(OpenAIVM.new);
