import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studlife_chat/questionBank/models/AuthenticatedUser.dart';
import 'package:studlife_chat/questionBank/persistent_models/AuthenticatedUserAdapter.dart';

class TeacherAuth {

  AuthenticatedUserAdapter box;
  TeacherAuth() {box = AuthenticatedUserAdapter();}

  Future<ValueListenable> getListenable() async {
    
    return box.storage.listenable;
  }

  void dispose() {
    box = null;
  }

  Future<bool> logout() async {
    if (box.getAll().length <= 0)
      return Future.delayed(Duration(milliseconds: 500)).then((value) => true);

    box.removeItem(box.getById(0));
    return true;
  }

  Future<bool> putTeacher(String email, String token) async {
    AuthenticatedUser user = AuthenticatedUser(email: email, token: token);
    try {
      box.addItem(user);
      return true;
    } catch (e) {
      print("ERROR PUTUSER $e");
      return false;
    }
  }

  Future<String> getTokenFromSignedInUser()
  async {
    
    if(box.getAll().length > 0)
    {
      try{
      String token = box.getById(0).token;
      return token;
      }catch(e)
      {
        print("ERROR AT GET TOKEN FROM SIGNED IN USER ${e.toString()}");
        return "";
      }
    }else{
      return "";
    }
  }

    Future<String> getEmailFromSignedInUser()
  async {
    
    if(box.getAll().length > 0)
    {
      try{
      String emailAddress = box.getById(0).emailAddress;
      return emailAddress;
      }catch(e)
      {
        print("ERROR AT GET TOKEN FROM SIGNED IN USER ${e.toString()}");
        return "";
      }
    }else{
      return "";
    }
  }

  String loginUrl = "https://studlife-srm.herokuapp.com/teacher/login";
  Future<bool> login(String email, String password) async {
    //return is token
    //no spaces
    email = email.trim();
    password = password.trim();
    var httpClient = Dio();
    print('\"{ "email" : "$email", "password": "$password" }\"');
    try {
      var response = await httpClient.post(loginUrl,
          data: '{ "email" : "$email", "password": "$password" }');

      if (response.statusCode == 200) {
        var loginObject = await json.decode(response.toString());
        await putTeacher(email, loginObject["token"]);
        return true;
      } else {
        print("CLIENT/SERVER ERROR ${response.statusCode} ${response.data}");
        return false;
      }
    } catch (e) {
      print(e);
      print("ERROR LOGIN ${e.toString()} ${(e as DioError).message}");
      return false;
    }
  }
}
