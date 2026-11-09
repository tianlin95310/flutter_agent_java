import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_agent_java/utils/http.dart';
import 'package:flutter_lib_common/main.dart';

class OpenAIResponse {
  Stream? stream;
}

class OpenAIRequest {
  String? question;
}

//流式输入数据结构如下,空行表示上一块结束
// data: {"choices":[{"finish_reason":null,"index":0,"delta":{"content":"开源"}}],"created":1793248180,"id":"chatcmpl-OqEObAVXDwKOSfo1JFxY6EdfakYs0C8g","model":"MiniCPM-V-4_6-Q4_K_M.gguf","system_fingerprint":"b9222-9a532ae4b","object":"chat.completion.chunk","timings":{"cache_n":0,"prompt_n":11,"prompt_ms":183.154,"prompt_per_token_ms":16.650363636363636,"prompt_per_second":60.058748375683855,"predicted_n":51,"predicted_ms":594.668,"predicted_per_token_ms":11.660156862745097,"predicted_per_second":85.76213954677232}}
//
// data: {"choices":[{"finish_reason":null,"index":0,"delta":{"content":"社区"}}],"created":1793248180,"id":"chatcmpl-OqEObAVXDwKOSfo1JFxY6EdfakYs0C8g","model":"MiniCPM-V-4_6-Q4_K_M.gguf","system_fingerprint":"b9222-9a532ae4b","object":"chat.completion.chunk","timings":{"cache_n":0,"prompt_n":11,"prompt_ms":183.154,"prompt_per_token_ms":16.650363636363636,"prompt_per_second":60.058748375683855,"predicted_n":52,"predicted_ms":609.444,"predicted_per_token_ms":11.720076923076922,"predicted_per_second":85.32367206831145}}
//
// data: {"choices":[{"finish_reason":null,"index":0,"delta":{"content":"开发"}}],"created":1793248180,"id":"chatcmpl-OqEObAVXDwKOSfo1JFxY6EdfakYs0C8g","model":"MiniCPM-V-4_6-Q4_K_M.gguf","system_fingerprint":"b9222-9a532ae4b","object":"chat.completion.chunk","timings":{"cache_n":0,"prompt_n":11,"prompt_ms":183.154,"prompt_per_token_ms":16.650363636363636,"prompt_per_second":60.058748375683855,"predicted_n":53,"predicted_ms":645.096,"predicted_per_token_ms":12.171622641509433,"predicted_per_second":82.15831442141945}}
//
// data: {"choices":[{"finish_reason":null,"index":0,"delta":{"content":"。"}}],"created":1793248180,"id":"chatcmpl-OqEObAVXDwKOSfo1JFxY6EdfakYs0C8g","model":"MiniCPM-V-4_6-Q4_K_M.gguf","system_fingerprint":"b9222-9a532ae4b","object":"chat.completion.chunk","timings":{"cache_n":0,"prompt_n":11,"prompt_ms":183.154,"prompt_per_token_ms":16.650363636363636,"prompt_per_second":60.058748375683855,"predicted_n":54,"predicted_ms":671.605,"predicted_per_token_ms":12.43712962962963,"predicted_per_second":80.40440437459519}}
//
// data: {"choices":[{"finish_reason":"stop","index":0,"delta":{}}],"created":1793248180,"id":"chatcmpl-OqEObAVXDwKOSfo1JFxY6EdfakYs0C8g","model":"MiniCPM-V-4_6-Q4_K_M.gguf","system_fingerprint":"b9222-9a532ae4b","object":"chat.completion.chunk","timings":{"cache_n":0,"prompt_n":11,"prompt_ms":183.154,"prompt_per_token_ms":16.650363636363636,"prompt_per_second":60.058748375683855,"predicted_n":55,"predicted_ms":685.688,"predicted_per_token_ms":12.467054545454545,"predicted_per_second":80.21140810397732}}
//
// data: [DONE]

//属于修饰符了
// interface / base / sealed / final

abstract interface class AIRepository {
  Stream<String> chat(dynamic request, {CancelToken? cancelToken, Future? abortTrigger});
}

// dart >= 3.6
class OpenAIRepositoryDio(final HttpService _httpService) implements AIRepository {
  /// 此种方式无法实现局部读取，请求会在完毕时一次性执行
  @override
  Stream<String> chat(request, {CancelToken? cancelToken, Future<dynamic>? abortTrigger}) async* {
    final response = await _httpService.dio.post<ResponseBody>(
      'http://127.0.0.1:10001/v1/chat/completions',
      data: request,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          // 按需添加 Authorization 等头
        },
      ),
    );
    final stream = response.data?.stream;
    print('stream is');
    print(stream);
    if (stream == null) {
      throw StateError('No response stream available');
    }
    yield* readFromStream(stream);
  }

  /// 读取Uint8List流
  Stream<String> readFromStream(Stream<Uint8List> stream) async* {
    final textStream = stream.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true));
    print('textStream is');
    print(textStream);

    String buffer = '';

    await for (final chunk in textStream) {
      buffer += chunk;

      print(chunk);

      // SSE 事件以 \n\n 分隔
      while (buffer.contains('\n\n')) {
        final endIndex = buffer.indexOf('\n\n');
        final eventBlock = buffer.substring(0, endIndex);
        buffer = buffer.substring(endIndex + 2);

        // 解析事件块中的 data: 行
        for (final line in eventBlock.split('\n')) {
          if (line.startsWith('data:')) {
            final data = line.substring(5).trimLeft();
            if (data == '[DONE]') return; // 根据 API 约定判断结束
            if (data.isNotEmpty) yield data;
          }
        }
      }
    }
  }
}

// dart >= 3.6
class OpenAIRepositoryHttp(final HttpService _httpService) implements AIRepository {
  /// 使用http包，支持流式请求
  @override
  Stream<String> chat(request, {CancelToken? cancelToken, Future<dynamic>? abortTrigger}) async* {
    Stream<String> response = await _httpService.makeStreamRequest(
      'http://127.0.0.1:10001/v1/chat/completions',
      request,
      abortTrigger: abortTrigger,
    );
    yield* response;
  }
}

final openAIDioProvider = Provider<OpenAIRepositoryDio>((Ref ref) {
  final httpService = ref.read(httpHelperProvider);
  return OpenAIRepositoryDio(httpService);
});

final openAIHttpProvider = Provider<OpenAIRepositoryHttp>((Ref ref) {
  final httpService = ref.read(httpHelperProvider);
  return OpenAIRepositoryHttp(httpService);
});
