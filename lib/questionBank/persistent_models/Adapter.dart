
import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class PersistentAdapter {

  bool remove(GetStorage storage,String KEY,dynamic obj) {
    try {
      String json = jsonEncode(obj);
      List<String> stored = (storage.read(KEY) ?? [] as List<String>);
      storage.write(KEY, stored..remove(json));
      return true;
    } catch (e) {
      return false;
    }
  }

  bool add(GetStorage storage,String KEY,dynamic obj) {
    try {
      storage.write(
        KEY,
        (storage.read(KEY) ?? [] as List<String>)..add(jsonEncode(obj)),
      );
    } catch (e) {
      return false;
    }
  }

}