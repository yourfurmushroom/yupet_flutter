import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}

class RegisterArea extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) sendToWs;

  const RegisterArea({super.key, required this.sendToWs});

  @override
  _RegisterAreaState createState() => _RegisterAreaState();
}

class _RegisterAreaState extends State<RegisterArea> {
  String userName = '';
  String password = '';
  String checkPassword='';
  String email="";


void validationData() {
    if (userName.isEmpty || email.isEmpty || password.isEmpty || checkPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位')),
      );
      return;
    }
    if (!RegExp(r'^[\w\.]+@([\w]+\.)+[\w]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的電子郵件')),
      );
      return;
    }
    if (password != checkPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密碼不匹配')),
      );
      return;
    }
    try {
      widget.sendToWs('register', {
        'userName': userName,
        'userPassword': hashPassword(password),
        'userEmail': email,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('註冊失敗: $e')),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          // margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '註冊',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: '帳號',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => userName = value),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密碼',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => password = value),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '確認密碼',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => checkPassword = value),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: '電子郵件',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => email = value),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(children: [
                  ElevatedButton(
                    onPressed: () =>
                        validationData(),
                    child: const Text('註冊', style: TextStyle(fontSize: 16)),
                  ),
                  Row(children: [
                    Text("如果擁有賬號"),
                    TextButton(onPressed: ()=>Navigator.pop(context), child: Text("點我登入",style: TextStyle(color: Colors.blue),))
                  ],)
                ],
              
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




