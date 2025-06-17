import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChartArea extends StatefulWidget {
  final BluetoothCharacteristic? characteristic;
  final Stream<List<int>> listener;
  final void Function(String, Map<String, dynamic>) sendToWs;
  final String petname;
  final void Function() disconnectDevice;
  const ChartArea({
    super.key,
    required this.sendToWs,
    this.characteristic,
    required this.listener,
    required this.petname,
    required this.disconnectDevice,
  });

  @override
  State<ChartArea> createState() => _ChartAreaState();
}

class _ChartAreaState extends State<ChartArea> with SingleTickerProviderStateMixin {
  late StreamSubscription<List<int>> _subscription;
  final double minY = -1.5;
  final double maxY = 1.5;
  final ListQueue<double> _data = ListQueue<double>.from(List.filled(200, 0.0));
  List<double> ecgTodb = [];

  late final Ticker _ticker;
  final int maxLength = 200;

  final List<List<double>> sosCoefficients = [
    [0.2929, 0.5858, 0.2929, 1.0, -0.0, 0.1716], // 示意濾波器
  ];
  List<List<double>> _filterState = [];

  @override
  void initState() {
    super.initState();

    _filterState = List.generate(sosCoefficients.length, (_) => List.filled(2, 0.0));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (widget.characteristic != null) {
      widget.characteristic!.setNotifyValue(true).then((_) {
        print("已啟用特性 ${widget.characteristic!.uuid} 的通知");
      }).catchError((e) {
        print("啟用通知失敗: $e");
      });
    }

    _subscription = widget.listener.listen(
      (value) {
        final ecgValues = parseEcg(value);
        for (var ecgValue in ecgValues) {
          final filteredValue = applyButterworthFilterSingle(ecgValue, sosCoefficients, _filterState);
          if (_data.length >= maxLength) _data.removeFirst();
          _data.addLast(filteredValue);
          saveTodbHandler(filteredValue);
        }
        setState(() {});
      },
      onError: (error) => print("資料流錯誤: $error"),
      onDone: () => print("資料流已關閉"),
    );

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

  List<double> parseEcg(List<int> data) {
    List<double> ecgValues = [];
    for (int i = 0; i < data.length - 1; i += 2) {
      int lowByte = data[i];
      int highByte = data[i + 1];
      int value = (highByte << 8) | lowByte;
      if (value >= 0x8000) value -= 0x10000;
      double normalized = value / 32768.0;
      ecgValues.add(normalized);
    }
    return ecgValues;
  }

  double applyButterworthFilterSingle(double input, List<List<double>> sos, List<List<double>> z) {
    double x = input;
    double y = x;
    for (int s = 0; s < sos.length; s++) {
      var c = sos[s];
      double b0 = c[0], b1 = c[1], b2 = c[2], a0 = c[3], a1 = c[4], a2 = c[5];
      y = b0 * x + z[s][0];
      z[s][0] = b1 * x - a1 * y + z[s][1];
      z[s][1] = b2 * x - a2 * y;
      x = y;
    }
    return y;
  }

   void saveTodbHandler(double ecgValue)
  {
    if(ecgTodb.length>=1000)
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
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ECGPainter(_data, minY: minY, maxY: maxY),
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

  ECGPainter(this.data, {this.minY = -1.5, this.maxY = 1.5});

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
