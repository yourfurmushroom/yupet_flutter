import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PairBlueTooth extends StatefulWidget {
  final bool isConnectedBluetooth;
  final VoidCallback setConnectedBluetooth;
  final Function(BluetoothDevice?, BluetoothCharacteristic?, Stream<List<int>>?)
      setBluetoothDevice;
  final BluetoothDevice? device;

  const PairBlueTooth({
    super.key,
    required this.isConnectedBluetooth,
    required this.setConnectedBluetooth,
    required this.setBluetoothDevice,
    required this.device,
  });

  @override
  _PairBlueToothState createState() => _PairBlueToothState();
}

class _PairBlueToothState extends State<PairBlueTooth> {
  bool _isScanning = false;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  final String targetServiceUuid = "713d0003-503e-4c75-ba94-3148f18d941e";
  final String targetCharacteristicUuid =
      "713d0003-503e-4c75-ba94-3148f18d941e";

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    if (!await _checkPermissions()) return;
    if (!await FlutterBluePlus.isOn) await FlutterBluePlus.turnOn();
    _startScan();
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses.values.any((status) => !status.isGranted)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要藍牙和位置權限')),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    try {
      // 過濾設備名稱為 "YuPet"
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      print('掃描錯誤: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // 停止掃描並斷開現有連線
      await FlutterBluePlus.stopScan();
      print("掃描已停止");
      await device.disconnect();
      await Future.delayed(const Duration(seconds: 2)); // 避免過於頻繁的連線請求

      // 監聽連線狀態
      _stateSubscription?.cancel();
      _stateSubscription = device.connectionState.listen((state) {
        print("連線狀態: $state");
        if (state == BluetoothConnectionState.connected) {
          widget.setConnectedBluetooth();
        } else if (state == BluetoothConnectionState.disconnected) {
          _reconnectDevice(device);
        }
      });

      // 連接到設備
      print("開始連線到設備: ${device.id}");
      await device.connect(timeout: const Duration(seconds: 30));
      await device.requestMtu(512); // 嘗試設置 MTU，接受設備限制
      print("設備回報的 MTU: ${await device.mtu.first}");

      // 發現服務和特性
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;
      String targetServiceUuid =
          "0000ee56-1212-efde-1523-785feabcd123"; // 自定義服務 UUID
      String targetCharacteristicUuid =
          "00000002-1212-efde-1523-785feabcd123"; // 假設這是 ECG 資料特性

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == targetServiceUuid) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                targetCharacteristicUuid) {
              targetCharacteristic = characteristic;
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
              }
              break;
            }
          }
          if (targetCharacteristic != null) break;
        }
      }

      // 設置 handleBluetoothReady
      if (targetCharacteristic != null) {
        Stream<List<int>> stream = targetCharacteristic.value; // 獲取資料流
        widget.setBluetoothDevice(device, targetCharacteristic, stream);
        
      } else {
        print("未找到目標特性 UUID: $targetCharacteristicUuid");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("未找到 ECG 資料特性")),
        );
      }

      // 關閉頁面（如果需要）
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("連線失敗: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("連線失敗: $e")));
      }
    }
  }

  Future<void> _reconnectDevice(BluetoothDevice device) async {
    await Future.delayed(const Duration(seconds: 5)); // 增加重連間隔
    await device.connect(timeout: const Duration(seconds: 30));
  }

  Future<void> _disconnectDevice() async {
    try {
      await widget.device?.disconnect();
      _characteristicSubscription?.cancel();
      widget.setBluetoothDevice(null, null, null);
      widget.setConnectedBluetooth();
    } catch (e) {
      print('斷開連線錯誤: $e');
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _characteristicSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnectedBluetooth) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('已連線到藍牙設備', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              widget.device?.name ?? '未知設備',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _disconnectDevice,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('斷開連線', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[200],
      child: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (context, scanningSnapshot) {
          if (scanningSnapshot.data == true) {
            return StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = snapshot.data!;
                return ListView(
                  children: results.isEmpty
                      ? [const Center(child: Text('未找到設備'))]
                      : results.map((r) {
                          return ListTile(
                            title: Text(
                              r.device.name.isNotEmpty
                                  ? r.device.name
                                  : r.device.id.toString(),
                            ),
                            subtitle: Text('信號強度: ${r.rssi} dBm'),
                            trailing: const Icon(Icons.bluetooth),
                            onTap: () => _connectToDevice(r.device),
                          );
                        }).toList(),
                );
              },
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('掃描已結束'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startScan,
                  child: const Text('重新掃描'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
