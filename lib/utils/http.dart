import 'package:flutter_lib_common/main.dart';

//无参，无状态，无依赖
final httpHelperProvider = Provider<HttpService>((ref) => HttpHelper.service);