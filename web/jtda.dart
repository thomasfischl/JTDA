library jtda;

class JtdaParser {

  String _data;
  Iterator<String> _stream;

  JtdaParser(this._data) {
    _stream = _data.split('\n').iterator;
  }

  List<JavaThreadDump> parse() {
    List<JavaThreadDump> threads = new List();

    JavaThreadDump thread = null;

    while (_stream.moveNext()) {
      String line = _stream.current;
      if (line.startsWith("\"") && line.contains("")) {
        thread = new JavaThreadDump();
        threads.add(thread);
        thread.name = line.substring(1, line.indexOf("\"", 1));
      }

      if (line.contains("java.lang.Thread.State")) {
        var state = line.replaceFirst("java.lang.Thread.State: ", "");
        var index = state.indexOf("(");
        index = index == -1 ? state.length : index;
        thread.state = state.substring(0, index).trim();
      }

      if (line.contains("- locked")) {
        thread.locks.add(line.substring(line.indexOf("<") + 1, line.indexOf(">")
            ));
      }

      if (line.contains("- waiting to lock")) {
        thread.waitingToLocks.add(line.substring(line.indexOf("<") + 1,
            line.indexOf(">")));
      }

      if (thread != null) {
        thread.dump.add(line);
      }
    }

    return threads;
  }
}

class JavaThreadDump {

  List<String> dump = new List();
  String name;
  Set<String> locks = new Set();
  List<String> waitingToLocks = new List();
  String state = "Unkown";

  String toString() {
    var text = "Thread: $name ($state)";
    if (locks.isNotEmpty) {
      text += "\n - locks: " + locks.reduce((value, l) => value + ", " + l);
    }
    if (waitingToLocks.isNotEmpty) {
      text += "\n - waitingToLocks: " + waitingToLocks.reduce((value, l) =>
          value + ", " + l);
    }
    return text;
  }

  static String getColor(String state) {
    switch (state) {
      case 'WAITING':
      case 'TIMED_WAITING':
        return "yellow";

      case 'RUNNABLE':
        return "green";

      case 'BLOCKED':
        return "red";
    }

    return "grey";
  }
}
