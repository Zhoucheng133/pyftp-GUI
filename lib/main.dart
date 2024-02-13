// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MainApp());

  doWhenWindowReady(() {
    const initialSize = Size(400, 300);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: MainView()
      ),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {

  Future<void> mainServer(bool value) async {
    if(path=="没有选择目录"){
      return;
    }
    setState(() {
      serverOn=value;
    });
    if (value == true) {
      // 执行命令
      Process.start('python3', ['-m', 'pyftpdlib', '-d', path])
      .then((Process process) {
        print('Command started with PID ${process.pid}');
        process.stdout.transform(utf8.decoder).listen((String data) {
          print('stdout: $data');
        });
        process.stderr.transform(utf8.decoder).listen((String data) {
          print('stderr: $data');
        });

        setState(() {
          pid=process.pid;
        });

        process.exitCode.then((int code) {
          print('Command exited with code $code');
        });
      });
    } else {
      // 杀死命令
      Process.killPid(pid);
    }
  }

  String path="没有选择目录";
  bool serverOn=false;
  int pid=0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: MoveWindow(),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "本地路径",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path,
                            maxLines: 2,
                            style: TextStyle(
                              color: path=="没有选择目录" ? Colors.grey[400] : Color.fromARGB(255, 107, 85, 167),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  TextButton(
                    onPressed: serverOn==false ? () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        setState(() {
                          path=selectedDirectory;
                        });
                      }else{
                        setState(() {
                          path="没有选择目录";
                        });
                      }
                    } : null,
                    child: Text("选择路径")
                  )
                ],
              ),
              SizedBox(height: 10,),
              Text(
                "启动服务",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 5,),
              Switch(
                value: serverOn, 
                splashRadius: 0,
                onChanged: (value)=>mainServer(value)
              )
            ],
          ),
        )
      ],
    );
  }
}