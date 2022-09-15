import 'dart:developer';

class Log {
  static LogLevel logLevel = LogLevel.VERBOSE;

  static bool logXmpp = true;

  static void v(String tag, String message) {
    if (logLevel.index <= LogLevel.VERBOSE.index) {
      print('V/[$tag]: $message');
    }
  }

  static void d(String tag, String message) {
    if (logLevel.index <= LogLevel.DEBUG.index) {
      print('D/[$tag]: $message');
    }
  }

  static void i(String tag, String message) {
    if (logLevel.index <= LogLevel.INFO.index) {
      print('I/[$tag]: $message');
    }
  }

  static void w(String tag, String message) {
    if (logLevel.index <= LogLevel.WARNING.index) {
      print('W/[$tag]: $message');
    }
  }

  static void e(String tag, String message) {
    if (logLevel.index <= LogLevel.ERROR.index) {
      print('E/[$tag]: $message');
    }
  }

  static void xmppp_receiving(String message) {
    if (logXmpp) {
      print('---Xmpp Receiving:---');
      print('$message');
    }
  }

  static void xmppp_sending(String message) {
    if (logXmpp) {
      print('---Xmpp Sending:---');
      print('$message');
    }
  }

}

enum LogLevel { VERBOSE, DEBUG, INFO, WARNING, ERROR, OFF }