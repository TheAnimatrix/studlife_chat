import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:studlife_chat/questionBank/persistent_models/Adapter.dart';

import '../models/DownloadHistory.dart';

class DownloadHistoryAdapter extends PersistentAdapter{
  GetStorage storage;

  DownloadHistoryAdapter(){storage= GetStorage(KEY);}

  final String KEY = "DownloadHistoryAdapter";

  List<DownloadHistory> getAll() {
    var user = (storage.read(KEY)??[] as List<String>);
    return user.map(
        (rawString) => new DownloadHistory.fromJson(jsonDecode(rawString)));
  }

  DownloadHistory getById(int id) {
    return getAll().elementAt(id);
  }

  bool addItem(obj) {
    return super.add(storage, KEY, obj);
  }

  bool removeItem(obj) {
    return super.remove(storage, KEY, obj);
  }
}
