import 'package:flutter/foundation.dart';

class ApiPath {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost/taskapp_server/api";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2/taskapp_server/api";

      default:
        return "http://localhost/taskapp_server/api";
    }
  }

  static String endpoint(String fileName) {
    return "$baseUrl/$fileName";
  }
}
