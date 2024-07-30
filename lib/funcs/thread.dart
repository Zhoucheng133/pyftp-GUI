import 'dart:io';

class MainServer {
  Process? _process;
  int? pid;
  int? pythonPid;

  void runCmd(String sharePath, String port, bool enableWrite, bool useLogin, String username, String password) async {
    var cmd = Platform.isWindows ? 'python' : 'python3';
    var args = ['-m', 'pyftpdlib', '-p', port, '-d', sharePath];
    if (enableWrite) {
      args.add('-w');
    }
    if (useLogin) {
      args.add('-u');
      args.add(username);
      args.add('-P');
      args.add(password);
    }


    try {
      _process = await Process.start(cmd, args, runInShell: false, mode: ProcessStartMode.detached);
      pid = _process?.pid;
    } catch (_) {
    }
  }

  void stopCmd() {
    if (_process != null) {
      try {
        _process?.kill();
      } catch (_) {}
    } else {
    }
  }
}