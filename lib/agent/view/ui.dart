import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_agent_java/agent/viewmodel/main.dart';
import 'package:flutter_lib_common/main.dart';
import 'package:flutter_lib_common/mixin/ui-interaction.dart';

import '../model/vo.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return HomeState();
  }
}

/// 导入import 'package:flutter_lib_common/main.dart';后，因为export语句，BaseStateRP 也被自动导入
class HomeState extends BaseStateRP {
  String _currentInput = '';

  final chatList = <ChatItem>[];

  final _dataBuffer = StringBuffer();

  int _inputMaxLines = 1;

  StreamSubscription<String>? _streamSubscription;

  Completer? _abortTrigger;

  ScrollController? _controller;

  FocusNode? _focusNode;

  TextEditingController? _textEditingController;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _controller = ScrollController();
    _textEditingController = TextEditingController();

    _focusNode?.addListener(() {
      if (_focusNode != null && _focusNode!.hasFocus) {
        _inputMaxLines = 5;
      } else {
        _inputMaxLines = 1;
      }
      setState(() {});
    });

    // _controller?.dispose();
    // _focusNode?.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant ConsumerStatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
  }

  @override
  Widget getBody(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              controller: _controller,
              padding: const EdgeInsetsGeometry.all(8),
              itemBuilder: (BuildContext context, int index) => getListItem(context, index),
              itemCount: chatList.length,
            ),
          ),
          Center(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSize(
                    duration: duration,
                    alignment: AlignmentGeometry.bottomStart,
                    child: Autocomplete<String>(
                      textEditingController: _textEditingController,
                      focusNode: _focusNode,
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) return const Iterable<String>.empty();
                        return ['/设置1', '/设置2'].where((item) => item.contains(value.text));
                      },
                      fieldViewBuilder:
                          (BuildContext context, TextEditingController control, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return Shortcuts(
                              shortcuts: {
                                LogicalKeySet(LogicalKeyboardKey.end): const SubmitIntent()
                              } ,
                              child: Actions(
                                actions: {
                                  SubmitIntent: CallbackAction<SubmitIntent>(
                                    onInvoke: (intent) {
                                      // 在这里执行提交逻辑
                                      print('Enter 提交');
                                      return null;
                                    },
                                  ),
                                },
                                child: TextField(
                                  focusNode: focusNode,
                                  maxLines: _inputMaxLines,
                                  controller: control,
                                  showCursor: true,
                                  onChanged: (value) => _currentInput = value,
                                  onSubmitted: (value) {
                                    print('onSubmitted');
                                    onFieldSubmitted.call();
                                  },
                                  decoration: InputDecoration(
                                    hintText: '请输入内容',
                                    contentPadding: EdgeInsetsDirectional.all(8),
                                    border: OutlineInputBorder(),
                                    // prefixIcon: Text('prefixIcon'),
                                    suffixIcon: TextFieldTapRegion(
                                      child: _inputMaxLines == 1
                                          ? Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
                                                IconButton(icon: Icon(Icons.keyboard_voice), onPressed: () {}),
                                                IconButton(icon: Icon(Icons.send), onPressed: onSendPressed),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
                                                IconButton(icon: Icon(Icons.keyboard_voice), onPressed: () {}),
                                                IconButton(icon: Icon(Icons.send), onPressed: onSendPressed),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                        return Align(
                          alignment: Alignment.topCenter, // 贴底，向上生长
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 200,
                              // 限制最大高度，避免顶到状态栏
                              height: 200,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (_, i) {
                                  final item = options.elementAt(i);
                                  return ListTile(title: Text(item), onTap: () => onSelected(item));
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _flushEvent(ChatItem currentItem) {
    final data = _dataBuffer.toString();
    _dataBuffer.clear();
    if (data.isEmpty) return;

    // 这里的 data 就是服务端推送的一条完整消息（通常是 JSON 字符串）
    // 在 setState 中更新 UI
    setState(() {
      final json = jsonDecode(data);
      final reasoningContent = json['choices'][0]['delta']['reasoning_content'] ?? '';
      final content = json['choices'][0]['delta']['content'] ?? '';
      // print('content = ' + (reasoning_content ?? content ?? json.toString()));
      setState(() {
        currentItem.type = 2;
        String model = json['model'];
        currentItem.actor = "${model.substring(0, 7)}：";
        currentItem.reasoningContent = currentItem.reasoningContent + reasoningContent;
        currentItem.content = currentItem.content + content;
        // 下一帧执行滚动动画
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller != null && _controller!.hasClients) {
            _controller!.animateTo(
              _controller!.position.maxScrollExtent,
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOut,
            );
          }
        });
        if (currentItem.content.isNotEmpty) {
          currentItem.reasonEnd = true;
        }
      });
    });
  }

  void onSendPressed() async {
    print('发送');
    if (_currentInput.isEmpty) {
      m_showSnackBar('请输入提问内容?', type: MsgType.error);
      return;
    }
    _streamSubscription?.cancel();

    final request = {
      "messages": [
        {"role": "user", "content": _currentInput},
      ],
      "stream": true,
      "return_progress": true,
      "reasoning_format": "auto",
      "backend_sampling": false,
      "timings_per_token": true,
    };

    addListener(_abortTrigger = Completer());
    chatList.add(
      ChatItem()
        ..actor = '我：'
        ..type = 1
        ..content = _currentInput,
    );

    final currentItem = ChatItem()
      ..reasoningContent = ''
      ..type = 2
      ..content = '';
    chatList.add(currentItem);

    final openaiVm = ref.read(openaiVmProvider.notifier);
    final response = openaiVm.chat(request, abortTrigger: _abortTrigger?.future);

    _streamSubscription = response.listen(
      (line) {
        openaiVm.listenBody(
          line,
          _dataBuffer,
          flushEvent: () {
            _flushEvent(currentItem);
          },
          streamSubscription: _streamSubscription,
        );
      },
      onError: (e) {
        print(e);
        /* 错误处理 */
      },
      onDone: () {
        _streamSubscription?.cancel();
        /* 流结束 */
      },
    );
    addListener(_streamSubscription);
  }

  Widget getListItem(BuildContext context, int index) {
    final currentItem = chatList[index];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: currentItem.type == 1 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: currentItem.type == 1 ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(currentItem.type == 1 ? Icons.account_circle_rounded : Icons.android, color: Colors.blue),
              ),
              Flexible(
                child: Text(
                  currentItem.actor,
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                currentItem.reasonEnd = !currentItem.reasonEnd;
              });
            },
            child: Text(
              currentItem.reasoningContent,
              style: TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: currentItem.reasonEnd ? 2 : 999,
              overflow: TextOverflow.fade,
            ),
          ),
          Text(currentItem.content, style: TextStyle(color: Colors.grey.shade900, fontSize: 13)),
        ],
      ),
    );
  }
}
