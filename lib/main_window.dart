import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:process_run/process_run.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPython();
    });
    windowManager.addListener(this);
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
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 144, 74, 66), width: 2.0),
                    ),
                    hintText: '输入路径或者选择',
                    isCollapsed: true,
                    contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
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
    prefs = await SharedPreferences.getInstance();
    String? python=whichSync(Platform.isWindows ? 'python' : 'python3');
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
                  // FilePickerResult? result = await FilePicker.platform.pickFiles();
                  // if (result != null) {
                  //   m.python.value=result.files.single.path!;
                  //   prefs.setString('python', result.files.single.path!);
                  //   if(context.mounted){
                  //     Navigator.pop(context);
                  //   }
                  // }
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
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Python 路径:'),
                  const SizedBox(width: 10,),
                  Expanded(child: Obx(()=>Text(
                    m.python.value,
                    overflow: TextOverflow.ellipsis,
                  ))),
                  const SizedBox(width: 10,),
                  TextButton(
                    onPressed: ()=>selectPython(context), 
                    child: const Text('选择')
                  )
                ],
              ),
              const SizedBox(height: 10,),
              
            ],
          ),
        )
      ],
    );
  }
}