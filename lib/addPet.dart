import 'dart:io';

import 'package:flutter/material.dart';

class Addpet extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) sendToWs;
  final void Function(String) addToList;
  final String userName;
  const Addpet({super.key, required this.sendToWs, required this.userName,required this.addToList});

  @override
  _Addpet createState() => _Addpet();
}

class _Addpet extends State<Addpet> {
  String name = "";
  String type = "";
  String age = "";
  String weight = "";
  String sex = "";
  String note = "";

  void validationData() {
    if (name.isEmpty ||
        type.isEmpty ||
        age.isEmpty ||
        weight.isEmpty ||
        sex.isEmpty ||
        note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位')),
      );
      return;
    }
    final ageNum = int.tryParse(age);
    final weightNum = double.tryParse(weight);

    if (ageNum == null || ageNum < 0 || ageNum > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的年齡')),
      );
      return;
    }

    if (weightNum == null || weightNum <= 0 || weightNum > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的體重')),
      );
      return;
    }
    try {
      widget.sendToWs('addpet', {
        'userName': widget.userName,
        'name': name,
        'type': type,
        'age': age,
        'weight': weight,
        'sex': sex,
        'note': note
      });
      Navigator.pop(context);
      widget.addToList(name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('新增失敗: $e')),
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
                'Pet Status',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'PetName',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => name = value),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Pet Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => type = value),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Pet age',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => age = value),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Pet weight',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => weight = value),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Pet Gender',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => sex = value),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => note = value),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => validationData(),
                      child: const Text('註冊', style: TextStyle(fontSize: 16)),
                    ),
                    Row(
                      children: [
                        Text("如果擁有賬號"),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "點我登入",
                              style: TextStyle(color: Colors.blue),
                            ))
                      ],
                    )
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
