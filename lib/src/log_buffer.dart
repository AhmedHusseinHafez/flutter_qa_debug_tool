class LogBuffer {
  static final List<String> pendingLogs = [];

  static void add(String log) {
    pendingLogs.add(log);
  }

  static List<String> fetch() => pendingLogs;

  static void clear() {
    pendingLogs.clear();
  }
}
