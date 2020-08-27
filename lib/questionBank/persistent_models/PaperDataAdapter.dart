import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:studlife_chat/questionBank/models/DownloadHistory.dart';
import 'package:studlife_chat/questionBank/persistent_models/Adapter.dart';

import '../models/PaperData.dart';

class PaperHistoryItemAdapter extends PersistentAdapter{
  GetStorage storage;

  PaperHistoryItemAdapter(){storage = GetStorage(KEY);}

  final String KEY = "PaperHistoryItem";

  List<PaperHistoryItem> getAll() {
    var user = (storage.read(KEY) ?? [] as List<String>);
    return user.map(
        (rawString) => new PaperHistoryItem.fromJson(jsonDecode(rawString)));
  }

  PaperHistoryItem getById(int id) {
    return getAll().elementAt(id);
  }

  bool addItem(obj) {
    return super.add(storage, KEY, obj);
  }

  bool removeItem(obj) {
    return super.remove(storage, KEY, obj);
  }


}
