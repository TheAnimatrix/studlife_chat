import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:studlife_chat/questionBank/models/PaperData.dart';
import 'package:studlife_chat/questionBank/persistent_models/PaperDataAdapter.dart';
import 'package:studlife_chat/questionBank/services/teacherAuth.dart';


import '../get_it.dart';

class TeacherLogic {
  String parentUrl = "https://studlife-srm.herokuapp.com/";
  String getFinalPaperUrl = "/finalpaper?sortBy=name:desc";
  String getCourseUrl = "/course";
  PaperHistoryItemAdapter paperBox;

  addItemToBox(PaperHistoryItem item) async {
    item.dateCreated = DateTime.now().toIso8601String();
    paperBox.addItem(item);
  }

  ValueListenable getListenable() {
    return paperBox.storage.listenable;
  }


  Future<List<String>> getSubjectCodes() async {
    List<String> courses = List();
    var client = http.Client();
    var token = await getIt<TeacherAuth>().getTokenFromSignedInUser();
    try {
      var response = await client
          .get("$parentUrl$getCourseUrl", headers: {"Authorization": token});
      print("${response.statusCode} yay , ${response.body}");
      if (response.statusCode == 200) {
        Map jsonResponse = json.decode(response.body);
        for (Map courseObj in jsonResponse["course"]) {
          courses.add(courseObj["coursename"]);
        }
        return courses;
      } else {
        print("ERROR");
        print(response.body);
        return [];
      }
    } catch (e) {
      print("ERROR");
      print(e.toString());
      return [];
    }
  }

  Future<dynamic> uploadFileWithDio(
      String newFileName, String courseName, bool isFinalPaper, File file,
      {bool newCourse = false}) async {
    var dio = Dio();

    var uploadURL = "";
    var token = await getIt<TeacherAuth>().getTokenFromSignedInUser();
    if (token.isEmpty) throw "No Token";

    if (isFinalPaper) {
      uploadURL = "$parentUrl/teacher/upload/$courseName/finalpaper";
    } else {
      uploadURL = "$parentUrl/teacher/upload/$courseName/ct";
    }
    print("TOKEN $token");

    Map<String, String> headers = {"Authorization": "Bearer $token"};

    if (newCourse) {
      var response = await dio.post("$parentUrl/teacher/upload/course",
          options: Options(headers: headers),
          data: "{\"coursename\":\"$courseName\"}");
      if (response.statusCode != 200) {
        throw "Failed to create new subject code";
      } else {
        print("Created new subject code");
      }
    }

    FormData formData = FormData.fromMap({
      "paper": await MultipartFile.fromFile(file.path, filename: newFileName),
    });

    var response = await dio.post(uploadURL,
        data: formData,
        options: Options(headers: headers, validateStatus: (s) => true),
        onSendProgress: (int sent, int total) {
      print("$sent $total");
    });

    print("${response.statusCode} ${response.toString()}");
    dio.close();
    return response;
  }

  Future<String> asyncFileUpload(String newFileName, String courseName,
      bool isFinalPaper, File file) async {
    //create multipart request for POST or PATCH method
    var uploadURL = "";
    var token = await getIt<TeacherAuth>().getTokenFromSignedInUser();
    if (token.isEmpty) return "";

    if (isFinalPaper) {
      uploadURL = "$parentUrl/teacher/upload/$courseName/finalpaper";
    } else {
      uploadURL = "$parentUrl/teacher/upload/$courseName/ct";
    }

    Map<String, String> headers = {"Authorization": token};

    try {
      var request = http.MultipartRequest("POST", Uri.parse(uploadURL));
      //add text fields
      request.headers.addAll(headers);
      //create multipart using filepath, string or bytes
      var pic = http.MultipartFile.fromBytes('paper', file.readAsBytesSync(),
          filename: newFileName);
      //add multipart to request
      request.files.add(pic);
      var response = await request.send();

      //Get the response from the server
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      print(responseString);
      return responseString;
    } catch (e) {
      print("STUPID ERROR ${e.toString()}");
      return "";
    }
  }

  Upload(File imageFile, bool isFinalPaper, String courseName) async {
    var uploadURL = "";

    if (isFinalPaper) {
      uploadURL = "$parentUrl/teacher/upload/$courseName/finalpaper";
    } else {
      uploadURL = "$parentUrl/teacher/upload/$courseName/ct";
    }

    var stream = new http.ByteStream(Stream.castFrom(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse(uploadURL);

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('paper', stream, length,
        filename: basename(imageFile.path));
    //contentType: new MediaType('image', 'png'));

    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }
}
