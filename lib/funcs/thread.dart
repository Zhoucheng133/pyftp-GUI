// ignore_for_file: unnecessary_brace_in_string_interps, prefer_typing_uninitialized_variables

// import 'dart:convert';
import 'dart:convert';
import 'dart:io';

class MainServer{
  Process? _process;
  var pid;
  var pythonPid;

  void runCmd(String sharePah, String port, bool enableWrite, bool useLogin, String username, String password) async {
    var cmd="${Platform.isWindows ? 'python' : 'python3' } -m pyftpdlib -p ${port} -d '${sharePah}' ${enableWrite?'-w':''} ${useLogin?'-u $username -P $password':''}";
    try {
      _process = await Process.start(cmd, [], runInShell: true);
      pid=_process?.pid;
      _process?.stderr.transform(utf8.decoder).listen((data) {
        if(data.contains("pid") && data.contains(">>>") && data.contains("<<<")){
          var st=data.indexOf('pid=');
          var end=data.indexOf(' <<<');
          pythonPid=data.substring(st+4, end);
        }
      }, onError: (_){});
    } catch (_) {}
  }

  void stopCmd(){
    if(pid!=null){
      Process.killPid(pid);
      Process.killPid(int.parse(pythonPid));
    }
  }
}