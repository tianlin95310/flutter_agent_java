import 'package:flutter/material.dart';
import 'package:flutter_lib_common/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

/// 导入import 'package:flutter_lib_common/main.dart';后，因为export语句，BaseState2026也被自动导入
class HomeState extends BaseState2026 {
  String _currentInput = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget getBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsetsGeometry.all(8),
              itemBuilder: (BuildContext context, int index) => getListItem(context, index),
              itemCount: 50,
            ),
          ),
          Center(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController.fromValue(TextEditingValue(text: _currentInput)),
                    showCursor: true,
                    onChanged: (value) => _currentInput = value,
                    autofillHints: ['aaa', 'bbb'],
                    decoration: InputDecoration(hintText: '请输入内容'),
                  ),
                ),
                ElevatedButton(onPressed: onSendPressed, child: Text('发送')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onSendPressed() {
    print('发送');
  }

  Widget getListItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('AAA'), Text('BBB')]),
    );
  }
}
