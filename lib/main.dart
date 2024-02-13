// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MainApp());

  doWhenWindowReady(() {
    const initialSize = Size(400, 500);
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

  String path="没有选择目录";

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
                  ElevatedButton(
                    onPressed: () async {
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
                    }, 
                    child: Text("选择路径")
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}