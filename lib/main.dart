// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyftp_gui/funcs/thread.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:process_run/which.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(400, 400),
    maximumSize: Size(400, 400),
    title: 'ptftp GUI'
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textTheme: GoogleFonts.notoSansScTextTheme(),
        splashColor: Colors.transparent,
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: const Content(),
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
    _init();
  }

  void _init() async {
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if(running){
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: const Text('服务在运行中'),
            content: const Text('你需要先关闭服务才能退出'),
            actions: [
              FilledButton(
                onPressed: ()=>Navigator.pop(context), 
                child: const Text('好的')
              )
            ],
          )
        );
      }else{
        await windowManager.destroy();
      }
    }
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
        return;
      }
    }
  }

  Future<void> initPython() async {
    pythonPath=whichSync('python')??whichSync('python3')??"";
    if(pythonPath==''){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: const Text('没有找到Python'),
            content: const Text('可能是因为没有配置环境变量，务必确认Python加入到系统的环境变量中'),
            actions: [
              ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                }, 
                child: const Text('好的')
              )
            ],
          )
        );
      });
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? writeGet = prefs.getBool('write');
    if(writeGet!=null){
      setState(() {
        write=writeGet;
      });
    }
    final String? sharePathGet = prefs.getString('sharePath');
    if(sharePathGet!=null){
      setState(() {
        sharePath.text=sharePathGet;
      });
    }
    final String? portGet = prefs.getString('port');
    if(portGet!=null){
      setState(() {
        port.text=portGet;
      });
    }
    final bool? useLoginGet = prefs.getBool('useLogin');
    if(useLoginGet!=null){
      setState(() {
        useLogin=useLoginGet;
      });
    }
    final String? usernameGet = prefs.getString('username');
    if(usernameGet!=null){
      setState(() {
        username.text=usernameGet;
      });
    }
    final String? passwordGet = prefs.getString('password');
    if(passwordGet!=null){
      setState(() {
        password.text=passwordGet;
      });
    }
  }

  var pythonPath='';
  var sharePath=TextEditingController();
  var port=TextEditingController();
  var address="";
  var running=false;
  var write=false;
  var useLogin=false;
  var username=TextEditingController();
  var password=TextEditingController();

  var mainThread=MainServer();

  Future<void> pickDir() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if(selectedDirectory!=null){
      sharePath.text=selectedDirectory;
    }
  }

  void showUserDialog(BuildContext context){
    showDialog(
      context: context, 
      builder: (BuildContext context)=>AlertDialog(
        title: const Text('用户设置'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Checkbox(
                      splashRadius: 0,
                      value: useLogin, 
                      onChanged: (value){
                        setState(() {
                          useLogin=value!;
                        });
                      }
                    ),
                    const SizedBox(width: 5,),
                    GestureDetector(
                      onTap: (){
                        setState((){
                          useLogin=!useLogin;
                        });
                      },
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text('登录以访问')
                      )
                    )
                  ],
                ),
                const SizedBox(height: 5,),
                TextField(
                  controller: username,
                  autocorrect: false,
                  enabled: useLogin,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: "用户名",
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    )
                  ),
                  style: const TextStyle(
                    fontSize: 13
                  ),
                ),
                const SizedBox(height: 10,),
                TextField(
                  controller: password,
                  enabled: useLogin,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "密码",
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    )
                  ),
                  style: const TextStyle(
                    fontSize: 13
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          FilledButton(
            onPressed: ()=>Navigator.pop(context), 
            child: const Text('完成')
          )
        ],
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "分享的目录",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10,),
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
                        style: const TextStyle(
                          fontSize: 13
                        ),
                      )
                    ),
                    const SizedBox(width: 10,),
                    FilledButton(
                      onPressed: running ? null : ()=>pickDir(), 
                      child: const Text(
                        '选取',
                        style: TextStyle(
                          fontSize: 13
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10,),
                const Text(
                  "FTP 服务端口号",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10,),
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
                        style: const TextStyle(
                          fontSize: 13
                        ),
                      )
                    ),
                    const SizedBox(width: 10,),
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
                      icon: const Icon(Icons.remove_rounded)
                    ),
                    const SizedBox(width: 5,),
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
                      icon: const Icon(Icons.add_rounded)
                    )
                  ],
                ),
                const SizedBox(height: 10,),
                const Text(
                  "使用访问权限",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    Checkbox(
                      splashRadius: 0,
                      value: write, 
                      onChanged: running ? null : (value){
                        setState(() {
                          write=value!;
                        });
                      }
                    ),
                    const SizedBox(width: 5,),
                    GestureDetector(
                      onTap: (){
                        if(running){
                          return;
                        }
                        setState(() {
                          write=!write;
                        });
                      },
                      child: MouseRegion(
                        cursor: running ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                        child: Text(
                          "允许写入",
                          style: TextStyle(
                            color: running ? Colors.grey[400] :Colors.black
                          ),
                        )
                      )
                    ),
                    Expanded(child: Container()),
                    ElevatedButton(
                      onPressed: running ? null: (){
                        showUserDialog(context);
                      }, 
                      child: const Row(
                        children: [
                          Icon(Icons.settings_rounded),
                          SizedBox(width: 5,),
                          Text("用户设置")
                        ],
                      )
                    )
                  ],
                ),
                const SizedBox(height: 40,),
                Row(
                  children: [
                    const Icon(
                      Icons.podcasts_rounded,
                    ),
                    const SizedBox(width: 5,),
                    Text("$address:${port.text}"),
                    Expanded(child: Container()),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: running, 
                        splashRadius: 0,
                        onChanged: (value) async {
                          if(pythonPath==''){
                            showDialog(
                              context: context, 
                              builder: (BuildContext context)=>AlertDialog(
                                title: const Text("启动服务失败"),
                                content: const Text("Python环境变量没有配置"),
                                actions: [
                                  FilledButton(
                                    onPressed: ()=>Navigator.pop(context), 
                                    child: const Text("好的")
                                  )
                                ],
                              )
                            );
                          }else if(sharePath.text.isEmpty){
                            showDialog(
                              context: context, 
                              builder: (BuildContext context)=>AlertDialog(
                                title: const Text("启动服务失败"),
                                content: const Text("没有选择分享目录"),
                                actions: [
                                  FilledButton(
                                    onPressed: ()=>Navigator.pop(context), 
                                    child: const Text("好的")
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
                              Directory dir=Directory(sharePath.text);
                              if(!dir.existsSync()){
                                await showDialog(
                                  context: context, 
                                  builder: (BuildContext context)=>AlertDialog(
                                    title: const Text('启动失败'),
                                    content: const Text('路径不合法，重新选择'),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: (){
                                          Navigator.pop(context);
                                        }, 
                                        child: const Text('好的')
                                      )
                                    ],
                                  )
                                );
                                return;
                              }
                              mainThread.runCmd(sharePath.text, port.text, write, useLogin, username.text, password.text);
                              setState(() {
                                running=true;
                              });
                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('write', write);
                              await prefs.setString('sharePath', sharePath.text);
                              await prefs.setString('port', port.text);
                              await prefs.setBool('useLogin', useLogin);
                              await prefs.setString('username', username.text);
                              await prefs.setString('password', password.text);
                            }
                          }
                        }
                      ),
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