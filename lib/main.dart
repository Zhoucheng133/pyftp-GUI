// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, unnecessary_brace_in_string_interps

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';

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

  Future<void> mainServer(bool value, BuildContext context) async {
    if(path=="没有选择目录"){
      showDialog(
        context: context, 
        builder: (BuildContext context)=>AlertDialog(
          title: Text("无法启动服务"),
          content: Text("没有选择路径"),
          actions: [
            FilledButton(
              onPressed: (){
                Navigator.pop(context);
              }, 
              child: Text("好的")
            )
          ],
        )
      );
      return;
    }
    setState(() {
      serverOn=value;
    });
    
    if (value == true) {
      try {
        await shell.run("python3 -m pyftpdlib -d ${path}");
      } on ShellException catch (_) {}
    } else {
      shell.kill();
    }
  }

  String path="没有选择目录";
  bool serverOn=false;
  int pid=0;
  var shell = Shell();

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
              Row(
                children: [
                  Switch(
                    value: serverOn, 
                    splashRadius: 0,
                    onChanged: (value)=>mainServer(value, context)
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: (){}, 
                    icon: Icon(Icons.settings_rounded),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}