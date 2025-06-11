import 'package:dog/register_area.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}

class LoginArea extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) sendToWs;

  const LoginArea({super.key, required this.sendToWs});

  @override
  _LoginAreaState createState() => _LoginAreaState();
}

class _LoginAreaState extends State<LoginArea> {
  String userName = '';
  String password = '';

  void registerHandler() {
  
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterPage(
          sendToWs:widget.sendToWs
          ),
        ),
      );
    }
  
  void validationData() {
    if (userName.isEmpty  || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位')),
      );
      return;
    }
    
    try {
      widget.sendToWs('login', {
        'userName': userName,
        'userPassword': hashPassword(password),
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登入失敗: $e')),
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
                '登入',
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
              const SizedBox(height: 30),
              Center(
                child: Column(children: [
                  ElevatedButton(
                    onPressed: () =>
                          validationData() ,
                    child: const Text('登入', style: TextStyle(fontSize: 16)),
                  ),
                  Row(children: [
                    Text("如果沒有賬號"),
                    TextButton(onPressed: registerHandler, child: Text("點我註冊",style: TextStyle(color: Colors.blue),))
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



class RegisterPage extends StatelessWidget {
  final void Function(String, Map<String, dynamic>) sendToWs;

  const RegisterPage({super.key, required this.sendToWs});

  @override
  Widget build(BuildContext context) {
    return RegisterArea(
      sendToWs: sendToWs,
       
    );
  }
}