import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:process_run/process_run.dart';
import 'package:pyftp_gui/funcs/dialogs.dart';
import 'package:pyftp_gui/funcs/thread.dart';
import 'package:pyftp_gui/variables/main_var.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {

  MainVar m=Get.put(MainVar());
  late final SharedPreferences prefs;
  MainServer server=MainServer();

  @override
  void initState() {
    super.initState();
    getAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPython();
    });
    windowManager.addListener(this);
  }

  String address='';
  
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if(m.running.value){
        showDialog(
          // ignore: use_build_context_synchronously
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
        await windowManager.setPreventClose(false);
        await windowManager.close();
      }
    }
  }

  Future<void> getAddress() async {
    prefs = await SharedPreferences.getInstance();
    await windowManager.setPreventClose(true);
    final String? path=prefs.getString("sharePath");
    if(path!=null){
      sharePath.text=path;
    }
    final String? port=prefs.getString("sharePort");
    if(port!=null){
      sharePort.text=port;
    }else{
      sharePort.text="2121";
    }
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

  Future<void> selectPython(BuildContext context)async{
    TextEditingController controller=TextEditingController();
    await showDialog(
      context: context, 
      builder: (context)=>AlertDialog(
        title: const Text('手动查找Python'),
        content: SizedBox(
          width: 400,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    hintText: '输入路径或者选择',
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                )
              ),
              const SizedBox(width: 10,),
              TextButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    setState(() {
                      controller.text=result.files.single.path!;
                    });
                  }
                }, 
                child: const Text('选择')
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: ()=>Navigator.pop(context), 
            child: const Text('取消')
          ),
          FilledButton(
            onPressed: (){
              m.python.value=controller.text;
              prefs.setString('python', controller.text);
              Navigator.pop(context);
            }, 
            child: const Text('完成')
          )
        ],
      )
    );
  }

  Future<void> initPython() async {
    String? python=prefs.getString('python');
    if(python!=null){
      m.python.value=python;
      return;
    }
    python=whichSync(Platform.isWindows ? 'python' : 'python3');
    if(python!=null){
      m.python.value=python;
    }else{
      if(context.mounted){
        showDialog(
          // ignore: use_build_context_synchronously
          context: context, 
          builder: (context)=>AlertDialog(
            title: const Text('没有找到Python'),
            content: const Text('你可以选择手动查找'),
            actions: [
              TextButton(
                onPressed: (){
                  windowManager.close();
                }, 
                child: const Text('退出')
              ),
              FilledButton(
                onPressed: () async {
                  await selectPython(context);
                }, 
                child: const Text('选择')
              )
            ],
          )
        );
      }
    }
  }

  bool useAuth=false;
  TextEditingController username=TextEditingController();
  TextEditingController password=TextEditingController();

  void auth(BuildContext context){
    showDialog(
      context: context, 
      builder: (context)=>AlertDialog(
        title: const Text('用户设置'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      splashRadius: 0,
                      value: useAuth, 
                      onChanged: (val){
                        if(val!=null){
                          setState(() {
                            useAuth=val;
                          });
                        }
                      }
                    ),
                    const SizedBox(width: 5,),
                    GestureDetector(
                      onTap: (){
                        setState(() {
                          useAuth=!useAuth;
                        });
                      },
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text('登录访问')
                      )
                    )
                  ],
                ),
                const SizedBox(height: 15,),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('用户名'),
                ),
                const SizedBox(height: 5,),
                TextField(
                  controller: username,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    hintText: '输入用户名',
                    enabled: useAuth,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15,),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('密码'),
                ),
                const SizedBox(height: 5,),
                TextField(
                  controller: password,
                  enabled: useAuth,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    hintText: '输入密码',
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                  ),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }
        ),
        actions: [
          FilledButton(
            onPressed: (){
              if(useAuth && (username.text.isEmpty || password.text.isEmpty)){
                showErr(context, '无法完成这个设置', '没有填写用户名或密码');
                return;
              }
              Navigator.pop(context);
            }, 
            child: const Text('完成')
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void minWindow(){
    windowManager.minimize();
  }

  void closeWindow(){
    windowManager.close();
  }

  TextEditingController sharePath=TextEditingController();
  TextEditingController sharePort=TextEditingController();
  bool enableWrite=false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 30,
          color: Colors.transparent,
          child: Platform.isWindows ? Row(
            children: [
              Expanded(child: DragToMoveArea(child: Container())),
              WindowCaptionButton.minimize(onPressed: ()=>minWindow(),),
              WindowCaptionButton.close(onPressed: (){
                closeWindow();
              },)
            ],
          ) : DragToMoveArea(child: Container())
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Python 路径:')
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    child: Obx(()=>
                      Tooltip(
                        message: m.python.value,
                        child: Text(
                          m.python.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    )
                  ),
                  const SizedBox(width: 10,),
                  TextButton(
                    onPressed: ()=>selectPython(context), 
                    child: const Text('选择')
                  )
                ],
              ),
              const SizedBox(height: 15,),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('分享路径')
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: sharePath.text,
                      child: TextField(
                        controller: sharePath,
                        enabled: false,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          hintText: '选择分享路径',
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  FilledButton(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if(selectedDirectory!=null){
                        setState(() {
                          sharePath.text=selectedDirectory;
                        });
                      }
                    }, 
                    child: const Text('选择')
                  )
                ],
              ),
              const SizedBox(height: 15,),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('端口号')
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sharePort,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15,),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('访问限制')
              ),
              const SizedBox(height: 5,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        splashRadius: 0,
                        value: enableWrite, 
                        onChanged: (val){
                          if(val!=null){
                            setState(() {
                              enableWrite=val;
                            });
                          }
                        }
                      ),
                      const SizedBox(width: 5,),
                      GestureDetector(
                        onTap: (){
                          setState(() {
                            enableWrite=!enableWrite;
                          });
                        },
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text('允许写入')
                        )
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  FilledButton(
                    onPressed: ()=>auth(context), 
                    child: const Text('用户设置')
                  )
                ],
              ),
              const SizedBox(height: 30,),
              Row(
                children: [
                  const Icon(
                    Icons.podcasts_rounded,
                  ),
                  const SizedBox(width: 5,),
                  Text("$address:${sharePort.text}"),
                  Expanded(child: Container()),
                  Obx(()=>
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        splashRadius: 0,
                        value: m.running.value, 
                        onChanged: (val){
                          if(val){
                            prefs.setString('sharePath', sharePath.text);
                            prefs.setString('sharePort', sharePort.text);
                            m.sharePath.value=sharePath.text;
                            m.sharePort.value=sharePort.text;
                            m.enableWrite.value=enableWrite;
                            m.useAuth.value=useAuth;
                            m.username.value=username.text;
                            m.password.value=password.text;
                            server.runCmd(context);
                          }else{
                            server.stopCmd();
                          }
                        }
                      ),
                    )
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