import 'dart:convert';

import 'package:dog/addPet.dart';
import 'package:dog/chart_area.dart';
import 'package:dog/login_area.dart';
import 'package:dog/navbar.dart';
import 'package:dog/pair_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter/services.dart';
// import 'dart:io' show Platform;
import 'dart:io';

String _getWebSocketUrl() {
  if (kIsWeb) {
    return 'ws://localhost:8888'; // Web 平台
  } else if (Platform.isAndroid) {
    return 'ws://192.168.50.98:8888'; // Android 模擬器
    // return 'ws://10.0.2.2:8888'; // Android 模擬器
  } else {
    return 'ws://192.168.50.98:8888'; // iOS 或其他
  }
}

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

bool loginStatus = false;
BluetoothDevice? device;
BluetoothCharacteristic? characteristic;
WebSocketChannel? ws=null;
String userName = "";
int quantity = 0;
List<String> petList = [];
Stream<List<int>>? listener;

class _HomePageState extends State<HomePage> {
  void addToList(String e) {
    petList.add(e);
  }

  @override
  void initState() {
    super.initState();
    print("重來了！！！！！！！！！！！！！！！！！！！！！！！！！！");
    initWebSocket();
  }

  void handleBluetoothReady(BluetoothDevice? d, BluetoothCharacteristic? c,Stream<List<int>>?l) {
    setState(() {
      print("這裡 $d $c");
      device = d;
      characteristic = c;
      listener=l;
    });
  }

  void initWebSocket() {
    ws = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));
    print(Uri.parse(_getWebSocketUrl()));
    ws!.stream.listen((message) {
      onMessage(message);
    }, onDone: () {
      onClose();
    }, onError: (error) {
      onError(error);
      ws = null;
      print(error);
    });
  }

  void onMessage(dynamic message) {
    print('收到訊息: $message');
    message = jsonDecode(message);
    switch (message['responseType']) {
      case "login":
        print('${message['message']}');
        if (message['status']) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('登入成功'),
              content: const Text('登入成功'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );
          setState((){print('✅ loginStatus 已設為 true');loginStatus = true;});
          userName = message['name'];
          quantity = message['quantity'];
          final petListJson = jsonDecode(message['petList']) as List;
          petList = petListJson.map((pet) => pet['name'].toString()).toList();
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('登入失敗'),
              content: Text("${message['message']}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );
        }
        break;
      case "register":
        print('${message['message']}');
        if (message['status']) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('註冊成功'),
              content: const Text('註冊成功，請登入'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );
          setState(() => loginStatus = true);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('註冊失敗'),
              content: Text("${message['message']}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  void onClose() {
    print('WebSocket 已關閉');
// 你可以選擇重新連線或顯示提示
  }

  void onError(error) {
    print('WebSocket 錯誤: $error');
  }

  void loginHandler() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (ws == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('網路連接失敗')),
      );
    } else {
      if (!loginStatus) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              sendToWs: sendToWs,
            ),
          ),
        );
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Dashboard(logoutHandler:logoutHandler)));
      }
    }
  }

void logoutHandler()
{
  setState(() {
    loginStatus=false;
  });
   Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
}
  void sendToWs(String flag, Map<String, dynamic> params) {
    final message = {
      'action': flag,
      'userName':userName,
      ...params,
    };
    if (ws != null) {
      ws!.sink.add(jsonEncode((message)));
    }
  }

  void navigateToBluetooth() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BluetoothPage(
              handleBluetoothReady: (e, c,l) => handleBluetoothReady(e, c,l),
              device: device)),
    );
  }

  void navigateToChart() {
    if (!loginStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未登入 請登入')),
      );
      return;
    }

    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未連接藍牙')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPet(
          userName: userName,
          petList: petList,
          characteristic: characteristic,
          sendToWs: sendToWs,
          loginHandler: loginHandler,
          addToList: addToList,
          listener:listener!,
          disconnectDevice:disconnectDevice,
        ),
      ),
    );
  }

  void navigateToDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Dashboard(logoutHandler:logoutHandler)),
    );
  }

void disconnectDevice() async {
    try {
      await device?.disconnect();
      handleBluetoothReady(null, null, null);
      setState(() => isConnectedBluetooth = !isConnectedBluetooth);
    } catch (e) {
      print('斷開連線錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: Navbar(
          actionName: '歐汪心動時刻',
          loginHandler: loginHandler,
        ),
        backgroundColor: Color.fromRGBO(252, 212, 125, 1),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (!loginStatus)
                      buildButton(context, "登入", loginHandler,
                          Icon(Icons.login_rounded)),
                    if (loginStatus)
                      buildButton(context, "儀表板", navigateToDashboard,
                          Icon(Icons.exit_to_app, color: Colors.white)),
                    buildButton(
                        context,
                        device == null ? "藍牙配對" : "藍牙已連接",
                        navigateToBluetooth,
                        device == null
                            ? Icon(Icons.bluetooth_disabled,
                                color: Colors.white)
                            : Icon(Icons.bluetooth, color: Colors.white)),
                    buildButton(
                        context,
                        "查看圖表",
                        navigateToChart,
                        Icon(
                          Icons.show_chart_sharp,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(
      BuildContext context, String text, VoidCallback onPressed, Icon icon) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 106, 161, 206),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon.icon,
              size: 80, // Logo 大小
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  final Function(BluetoothDevice?, BluetoothCharacteristic?,Stream<List<int>>?)
      handleBluetoothReady;
  final BluetoothDevice? device;
  const BluetoothPage(
      {super.key, required this.handleBluetoothReady, required this.device});

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

bool isConnectedBluetooth = false;
class _BluetoothPageState extends State<BluetoothPage> {

  void setConnectedBluetooth() {
    setState(() => isConnectedBluetooth = !isConnectedBluetooth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(
        actionName: '藍牙配對',
        loginHandler: () {},
      ),
      body: PairBlueTooth(
        isConnectedBluetooth: isConnectedBluetooth,
        setConnectedBluetooth: setConnectedBluetooth,
        setBluetoothDevice: (e, c,l) => widget.handleBluetoothReady(e, c,l),
        device: widget.device,
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final void Function(String, Map<String, dynamic>) sendToWs;

  const LoginPage({super.key, required this.sendToWs});

  @override
  Widget build(BuildContext context) {
    return LoginArea(sendToWs: sendToWs);
  }
}

class Dashboard extends StatelessWidget {
  final Function() logoutHandler;
  const Dashboard({super.key,required this.logoutHandler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 106, 161, 206),
        appBar: Navbar(
          actionName: '儀表板',
          loginHandler: () {},
        ),
        body: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4, // 保持寬高相同
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // ✅ 使用 circle 取代 borderRadius
              ),
              child: Center(
                child: Icon(
                  Icons.settings,
                  size:100,
                  color: Colors.blue, // 這裡原本是白色，可能會看不到
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                
              ),
              child: Column(
                children: [
                  
                ],
              ),
            ),

            SizedBox(height: 20),
            Container(
              width:MediaQuery.of(context).size.width,
              child: ElevatedButton(onPressed: logoutHandler, child:Text("logout")),
            )
          ],
        ));
  }
}

class SelectPet extends StatefulWidget {
  final BluetoothCharacteristic? characteristic;
  final String userName;
  final void Function(String, Map<String, dynamic>) sendToWs;
  final void Function(String) addToList;
  final void Function() loginHandler;
  final List<String> petList;
  final Stream<List<int>> listener;
  final void Function()disconnectDevice;
  const SelectPet(
      {super.key,
      required this.userName,
      required this.petList,
      required this.characteristic,
      required this.sendToWs,
      required this.loginHandler,
      required this.addToList,
      required this.listener,
      required this.disconnectDevice});
  @override
  _SelectPet createState() => _SelectPet();
}

class _SelectPet extends State<SelectPet> {
  String petName = "";

  void navigateToChart() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowChart(
          petName: petName,
          characteristic: widget.characteristic,
          sendToWs: widget.sendToWs,
          loginHandler: widget.loginHandler,
          listener:widget.listener,
          disconnectDevice:widget.disconnectDevice,
        ),
      ),
    );
  }

  void navigateToAddPet(void Function(String) addToList) {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Addpet(
          sendToWs: widget.sendToWs,
          userName: widget.userName,
          addToList: addToList,
        ),
      ),
    );
  }

  void setPetName(String e) {
    petName = e;
    navigateToChart();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: Navbar(
          actionName: "選擇寵物",
          loginHandler: widget.loginHandler,
          backHandler: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Color.fromRGBO(80, 100, 135, 1),
        body: Center(
            child: Container(
          width: MediaQuery.of(context).size.width * 1,
          height: MediaQuery.of(context).size.height * 1,
          child: Column(children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
                  child: Column(
                children: widget.petList
                    .map((e) =>
                        selectField(MediaQuery.of(context).size, e, setPetName))
                    .toList(),
              )),
            ),
            SizedBox(height: 20),
            Container(
              child: Center(
                child: ElevatedButton(
                  onPressed: () => navigateToAddPet(widget.addToList),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blueAccent),
                  ),
                  child: Text(
                    "新增寵物",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        )));
  }

  Widget selectField(Size size, String name, void Function(String) setPetName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 40, 0, 0),
      width: size.width * 0.8,
      height: size.height * 0.1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setPetName(name),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: Colors.white),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShowChart extends StatelessWidget {
  final BluetoothCharacteristic? characteristic;
  final void Function(String, Map<String, dynamic>) sendToWs;
  final void Function() loginHandler;
  final String petName;
  final Stream<List<int>> listener;
  final void Function()disconnectDevice;

  const ShowChart(
      {super.key,
      required this.characteristic,
      required this.sendToWs,
      required this.loginHandler,
      required this.petName,
      required this.listener,
      required this.disconnectDevice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(
        actionName: "動態折線圖",
        loginHandler: loginHandler,
        backHandler: () {
          Navigator.of(context).pop();
        },
      ),
      backgroundColor: const Color.fromARGB(255, 106, 161, 206),
      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
              padding: EdgeInsets.all(5),
              child: Row(
                children: [
                  renderDataArea(MediaQuery.of(context).size, "寵物名字："),
                  renderDataArea(MediaQuery.of(context).size, petName)
                ],
              ),
            ),
            Container(
                width: MediaQuery.of(context).size.width * 1,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.white),
                  color: Colors.black,
                ),
                child: ChartArea(sendToWs:sendToWs,characteristic: characteristic,listener:listener,petname:petName,disconnectDevice:disconnectDevice)),
            Container(
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(200, 0, 250, 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            renderDataArea(
                                MediaQuery.of(context).size, "heart rate: "),
                            renderDataArea(MediaQuery.of(context).size, "NA"),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            renderDataArea(
                                MediaQuery.of(context).size, "Hrv: "),
                            renderDataArea(MediaQuery.of(context).size, "NA"),
                          ],
                        )
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget renderDataArea(Size size, String value) {
    return Container(
      child: Text(
        value,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
