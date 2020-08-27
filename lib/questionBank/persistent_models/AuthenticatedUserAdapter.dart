import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:studlife_chat/questionBank/persistent_models/Adapter.dart';

import '../models/AuthenticatedUser.dart';

class AuthenticatedUserAdapter extends PersistentAdapter{

  GetStorage storage;
  AuthenticatedUserAdapter(){storage = GetStorage(KEY);}

  static const String KEY = "AuthenticatedUser";

  List<AuthenticatedUser> getAll() {
    var user = (storage.read(KEY) as List<String>);
    return user.map((rawString)=>new AuthenticatedUser.fromJson(jsonDecode(rawString)));
  }

  AuthenticatedUser getById(int id) {
    return getAll().elementAt(id);
  }

  bool addItem(obj) {
    return super.add(storage, KEY, obj);
  }

  bool removeItem(obj) {
    return super.remove(storage, KEY, obj);
  }

}