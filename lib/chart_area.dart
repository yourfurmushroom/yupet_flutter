import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:dog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChartArea extends StatefulWidget {
  final BluetoothCharacteristic? characteristic;
  final Stream<List<int>>listener;
  final void Function(String, Map<String, dynamic>) sendToWs;
  final String petname;
  final void Function()disconnectDevice;
  const ChartArea({super.key,required this.sendToWs, this.characteristic,required this.listener,required this.petname,required this.disconnectDevice});

  @override
  State<ChartArea> createState() => _ChartAreaState();
}

class _ChartAreaState extends State<ChartArea> with SingleTickerProviderStateMixin {
  
late StreamSubscription<List<int>> _subscription;
final double minY = -2.0;  // Y 軸最小值
final double maxY = 2.0;
final ListQueue<double> _data = ListQueue<double>.from(List.filled(200, 0.0));
List<double> ecgTodb=[];

  late final Ticker _ticker;
  // late final Timer _dataTimer;
  final int maxLength = 200; // 顯示的資料點數

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // _dataTimer = Timer.periodic(const Duration(milliseconds: 1), (_) {
    //   final newValue = sin(DateTime.now().microsecondsSinceEpoch / 100000.0) + Random().nextDouble() * 0.1;
    //   if (_data.length >= maxLength) _data.removeFirst();
    //   _data.addLast(newValue);
    // });

// __________________________________________________________________handle ecg__________________________________________________________________
  
  double parseEcg(List<int> data) {
  if (data.length < 5) return 0.0;
  List<double> ecgValues = [];
  for (int i = 3; i < data.length - 1; i += 2) {
    int highByte = data[i];
    int lowByte = data[i + 1];
    int value = (highByte << 8) | lowByte; 
    double normalizedValue = (value / 65535.0) * (maxY - minY) + minY; 
    ecgValues.add(normalizedValue);
  }
  return ecgValues.isNotEmpty ? ecgValues.first : 0.0; 
}

  void saveTodbHandler(double ecgValue)
  {
    if(ecgTodb.length>=200)
    {
      widget.sendToWs("addECGdata",{
        'data':ecgTodb,
        'petname':widget.petname
      });
      ecgTodb.length=0;
      return;
    }
    ecgTodb.add(ecgValue);
  }

if (widget.characteristic != null) {
      widget.characteristic!.setNotifyValue(true).then((_) {
        print("已啟用特性 ${widget.characteristic!.uuid} 的通知");
      }).catchError((e) {
        print("啟用通知失敗: $e");
      });
    }
try {
  print(widget.listener);
      _subscription = widget.listener.listen(
        (value) {
          final ecgValue = parseEcg(value); // 解析 ECG 資料
          print(ecgValue);
          if (_data.length >= maxLength) _data.removeFirst();
          _data.addLast(ecgValue);
          saveTodbHandler(ecgValue);
          setState(() {}); // 更新圖表
        },
        onError: (error) {
          print("資料流錯誤: $error");
        },
        onDone: () {
          print("資料流已關閉");
        },
      );
    } catch (e) {
      print("訂閱資料流失敗: $e");
    }
// __________________________________________________________________________________________________________________________________________________

    // 每幀重繪（約 60fps）
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    widget.sendToWs("addECGdata",{
        'data':ecgTodb,
        'petname':widget.petname
      });

    widget.disconnectDevice();
      
    _subscription.cancel();
    // _dataTimer.cancel();
    _ticker.dispose();
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: ECGPainter(_data, minY: -2, maxY: 2),
            size: Size.infinite,
          ),
        ),
      );

  }
}

class ECGPainter extends CustomPainter {
  final ListQueue<double> data;
  final double minY;
  final double maxY;

  ECGPainter(this.data, {this.minY = -2, this.maxY = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dataList = data.toList();
    final dx = size.width / (dataList.length - 1).clamp(1, double.infinity);
    final scaleY = size.height / (maxY - minY);

    for (int i = 0; i < dataList.length; i++) {
      final x = i * dx;
      final y = size.height - ((dataList[i] - minY) * scaleY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) => true;
}
