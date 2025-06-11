import 'dart:convert'; // 用於 JSON 解析
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket JSON Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebSocketPage(),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});

  @override
  _WebSocketPageState createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  WebSocketChannel? _channel;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // 儲存解析後的訊息
  bool _isConnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // 預設 URL
    _urlController.text = _getWebSocketUrl();
    _connectWebSocket();
  }

  // 選擇適當的 WebSocket URL 根據平台
  String _getWebSocketUrl() {
    if (kIsWeb) {
      return 'ws://localhost:8888'; // Web 平台
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8888'; // Android 模擬器
    } else {
      return 'ws://localhost:8888'; // iOS 或其他
    }
  }

  // 連接到 WebSocket 伺服器
  Future<void> _connectWebSocket() async {
    if (_isConnecting || _retryCount >= _maxRetries) return;

    final url = _urlController.text.isEmpty ? _getWebSocketUrl() : _urlController.text;
    setState(() {
      _isConnecting = true;
      _messages.add({
        'type': 'status',
        'content': '嘗試連線到 $url (重試 ${_retryCount + 1}/$_maxRetries)...',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    });

    try {
      _channel = IOWebSocketChannel.connect(
        url,
        pingInterval: const Duration(seconds: 10), // 保持連線
      );

      // 監聽伺服器傳來的訊息
      _channel!.stream.listen(
        (data) {
          try {
            // 解析 JSON
            final json = jsonDecode(data) as Map<String, dynamic>;
            final type = json['type'] as String? ?? 'unknown';
            final content = json['content'] as String? ?? '無內容';
            final timestamp = json['timestamp'] as int? ?? 0;
            setState(() {
              _messages.add({
                'type': type,
                'content': '收到: $content',
                'timestamp': timestamp,
              });
              _retryCount = 0; // 重置重試計數
            });
          } catch (e) {
            setState(() {
              _messages.add({
                'type': 'error',
                'content': 'JSON 解析失敗: $e (原始資料: $data)',
                'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              });
            });
          }
        },
        onError: (error, stackTrace) {
          setState(() {
            _messages.add({
              'type': 'error',
              'content': '連線錯誤: $error\n堆疊: $stackTrace',
              'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            });
          });
          _retryConnection();
        },
        onDone: () {
          setState(() {
            _messages.add({
              'type': 'status',
              'content': '連線已關閉',
              'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            });
          });
          _retryConnection();
        },
      );

      setState(() {
        _messages.add({
          'type': 'status',
          'content': '已連線到 $url',
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        _isConnecting = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _messages.add({
          'type': 'error',
          'content': '連線失敗: $e\n堆疊: $stackTrace',
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        _isConnecting = false;
      });
      _retryConnection();
    }
  }

  // 重試連線
  void _retryConnection() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(const Duration(seconds: 2), () {
        _connectWebSocket();
      });
    } else {
      setState(() {
        _messages.add({
          'type': 'error',
          'content': '達到最大重試次數，請檢查伺服器或網路設定。',
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      });
    }
  }

  // 發送 JSON 格式的訊息
  void _sendMessage() {
    if (_messageController.text.isNotEmpty && _channel != null) {
      final jsonMessage = jsonEncode({
        'type': 'message',
        'content': _messageController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      _channel!.sink.add(jsonMessage);
      setState(() {
        _messages.add({
          'type': 'message',
          'content': '發送: ${_messageController.text}',
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      });
      _messageController.clear();
    } else {
      setState(() {
        _messages.add({
          'type': 'error',
          'content': '無法發送: 未連線',
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket JSON Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'WebSocket URL'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: '輸入訊息內容'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('發送 JSON 訊息'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectWebSocket,
              child: const Text('重試連線'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final timestamp = msg['timestamp'] as int;
                  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                  return ListTile(  
                    title: Text('[${msg['type']}] ${msg['content']}'),
                    subtitle: Text('時間: $dateTime'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}