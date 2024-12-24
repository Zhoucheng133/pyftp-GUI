import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:process_run/process_run.dart';
import 'package:pyftp_gui/funcs/dialogs.dart';
import 'package:pyftp_gui/variables/main_var.dart';

class MainServer {

  late Shell shell;
  final MainVar m=Get.put(MainVar());

  Future<void> runCmd(BuildContext context) async {
    if(m.sharePath.value.isEmpty){
      showErr(context, '启动失败', '没有选择分享路径');
      return;
    }else if(m.sharePort.value.isEmpty){
      showErr(context, '启动失败', '端口号为空');
      return;
    }else if(m.sharePort.value.length>5 || m.sharePort.value.length<4){
      showErr(context, '启动失败', '端口号号不合法');
      return;
    }
    shell=Shell();
    final sharePath=m.sharePath.value.replaceAll('\\', '/');
    final pythonPath=m.python.value.replaceAll('\\', '/');
    var cmd = pythonPath;
    cmd+=' -m pyftpdlib -p ${m.sharePort.value} -d "$sharePath"';
    if(m.enableWrite.value){
      cmd+=' -w';
    }
    if(m.useAuth.value){
      cmd+=' -u ${m.username.value} -P ${m.password.value}';
    }
    m.running.value=true;
    try {
      await shell.run(cmd);
    } on ShellException catch (_) {}
  }

  void stopCmd(){
    try {
      shell.kill();
    } catch (_) {}
    m.running.value=false;
  }
}