import 'dart:io';

import 'package:process_run/process_run.dart';

class MainServer {

  late Shell shell;

  void runCmd(String sharePath, String port, bool enableWrite, bool useLogin, String username, String password) async {
    shell=Shell();
    var cmd = Platform.isWindows ? 'python' : 'python3';
    sharePath=sharePath.replaceAll('\\', '/');
    cmd+=' -m pyftpdlib -p $port -d "$sharePath"';
    if(enableWrite){
      cmd+=' -w';
    }
    if(useLogin){
      cmd+=' -u $username -P $password';
    }
    try {
      await shell.run(cmd);
    } on ShellException catch (_) {}
  }

  void stopCmd(){
    try {
      shell.kill();
    } catch (_) {}
  }
}