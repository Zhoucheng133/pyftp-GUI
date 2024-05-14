// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_brace_in_string_interps

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pyftp_gui/funcs/thread.dart';
import 'package:window_manager/window_manager.dart';
import 'package:process_run/which.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 300),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(400, 300),
    maximumSize: Size(400, 300),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: Content(),
    );
  }
}

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    initPython();
    port.text="2121";
    getAddress();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> getAddress() async {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      final addresses = interface.addresses;
      final localAddresses = addresses.where((address) => !address.isLoopback && address.type.name=="IPv4");
      for (final localAddress in localAddresses) {
        setState(() {
          address=localAddress.address;
        });
      }
    }
  }

  void initPython(){
    pythonPath.text=whichSync('python')??whichSync('python3')??"";
  }

  var pythonPath=TextEditingController();
  var sharePath=TextEditingController();
  var port=TextEditingController();
  var address="";
  var running=false;

  var mainThread=MainServer();

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      pythonPath.text=result.files.single.path!;
    }
  }

  Future<void> pickDir() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if(selectedDirectory!=null){
      sharePath.text=selectedDirectory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 30,
            child: Row(
              children: [
                Expanded(child: DragToMoveArea(child: Container(),)),
                WindowCaptionButton.minimize(
                  onPressed: (){
                    windowManager.minimize();
                  },
                ),
                WindowCaptionButton.close(
                  onPressed: (){
                    windowManager.close();
                  },
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pythonPath,
                        autocorrect: false,
                        // enabled: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          hintText: "选取Python程序地址",
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )
                        ),
                        style: TextStyle(
                          fontSize: 13
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    FilledButton(
                      onPressed: running ? null : ()=>pickFile(), 
                      child: Text(
                        '选取',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      )
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: false,
                        controller: sharePath,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: "选取分享的目录",
                          contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )
                        ),
                        style: TextStyle(
                          fontSize: 13
                        ),
                      )
                    ),
                    SizedBox(width: 10,),
                    FilledButton(
                      onPressed: running ? null : ()=>pickDir(), 
                      child: Text(
                        '选取',
                        style: TextStyle(
                          fontSize: 13
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: port,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: false,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )
                        ),
                        style: TextStyle(
                          fontSize: 13
                        ),
                      )
                    ),
                    SizedBox(width: 10,),
                    IconButton(
                      onPressed: running ? null : (){
                        int number=int.parse(port.text);
                        if(number<=1000){
                          return;
                        }
                        number-=1;
                        setState(() {
                          port.text=number.toString();
                        });
                      }, 
                      icon: Icon(Icons.remove_rounded)
                    ),
                    SizedBox(width: 5,),
                    IconButton(
                      onPressed: running ? null : (){
                        int number=int.parse(port.text);
                        if(number>=10000){
                          return;
                        }
                        number+=1;
                        setState(() {
                          port.text=number.toString();
                        });
                      }, 
                      icon: Icon(Icons.add_rounded)
                    )
                  ],
                ),
                SizedBox(height: 40,),
                Row(
                  children: [
                    Icon(
                      Icons.podcasts_rounded,
                    ),
                    SizedBox(width: 5,),
                    Text("${address}:${port.text}"),
                    Expanded(child: Container()),
                    FilledButton(
                      onPressed: (){
                        if(pythonPath.text.isEmpty){
                          showDialog(
                            context: context, 
                            builder: (BuildContext context)=>AlertDialog(
                              title: Text("启动服务失败"),
                              content: Text("没有选择Python程序地址"),
                              actions: [
                                FilledButton(
                                  onPressed: ()=>Navigator.pop(context), 
                                  child: Text("好的")
                                )
                              ],
                            )
                          );
                        }else if(sharePath.text.isEmpty){
                          showDialog(
                            context: context, 
                            builder: (BuildContext context)=>AlertDialog(
                              title: Text("启动服务失败"),
                              content: Text("没有选择分享目录"),
                              actions: [
                                FilledButton(
                                  onPressed: ()=>Navigator.pop(context), 
                                  child: Text("好的")
                                )
                              ],
                            )
                          );
                        }else{
                          if(running){
                            mainThread.stopCmd();
                            setState(() {
                              running=false;
                            });
                          }else{
                            mainThread.runCmd(pythonPath.text, sharePath.text, port.text);
                            setState(() {
                              running=true;
                            });
                          }
                        }
                        
                      }, 
                      child: Text(running ? '停止':'启动')
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}