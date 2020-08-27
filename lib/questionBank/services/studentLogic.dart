import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:studlife_chat/questionBank/models/DownloadHistory.dart';
import 'package:studlife_chat/questionBank/models/Paper.dart';
import 'package:studlife_chat/questionBank/persistent_models/DownloadHistoryAdapter.dart';
import 'package:studlife_chat/questionBank/persistent_models/PaperDataAdapter.dart';

class Logic {
//HTTP LOGIC

  StreamController<int> controller;

  String parentUrl = "https://studlife-srm.herokuapp.com/";
  String getFinalPaperUrl = "/finalpaper?sortBy=name:desc";
  String getCtPaperUrl = "/ct";
  String getCourseUrl = "/course";
  String token =
      "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1ZTk4OTQ0MjZiODcxMzAwMTdiOTFmNTAiLCJpYXQiOjE1ODcwNTc3MzB9.2rwQIP-zNJYlniV6HtZWkTOcqrz-Y_OFNvqQn-6fmcw";
  List<String> courses, ids;
  DownloadHistoryAdapter paperBox;
  Logic() {
    paperBox = DownloadHistoryAdapter();
    controller = StreamController<int>.broadcast();
    courses = List();
    ids = List();
  }

  dispose() {
    controller?.close();
  }

  remove(int index) {
    if (index >= courses.length) return;

    courses.removeAt(index);
    controller?.sink?.add(courses.length);
  }

  Future<List<DownloadPaper>> getFinalPapers(String subject) async {
    List<DownloadPaper> finalPapers = List();
    var client = http.Client();
    try {
      var response = await client.get(
          "$parentUrl$getCourseUrl/$subject$getFinalPaperUrl",
          headers: {"Authorization": token});
      if (response.statusCode == 200) {
        var jsonArr = json.decode(response.body);
        for (var item in jsonArr) {
          finalPapers.add(DownloadPaper(
              fileName: item["filename"],
              id: item["_id"],
              downloaded: await alreadyDownloaded(item["_id"])));
        }
      } else {
        print("ERROR WITH RESPONSE $response");
      }
    } catch (e) {
      print("HTTP ERROR $e");
    }

    return finalPapers;
  }

  Future<List<DownloadPaper>> getCtPapers(String subject) async {
    List<DownloadPaper> ctPapers = [];
    var client = http.Client();
    try {
      var response = await client.get(
          "$parentUrl$getCourseUrl/$subject$getCtPaperUrl",
          headers: {"Authorization": token});
      if (response.statusCode == 200) {
        var jsonArr = json.decode(response.body);
        for (var item in jsonArr) {
          ctPapers.add(DownloadPaper(
              fileName: item["filename"],
              id: item["_id"],
              downloaded: await alreadyDownloaded(item["_id"])));
        }
      } else {
        print("ERROR WITH RESPONSE $response");
      }
    } catch (e) {
      print("HTTP ERROR $e");
    }

    return ctPapers;
  }

  List<String> tempList;
  filterCourses(String searchWord) {
    if (tempList == null) tempList = courses;
    if (searchWord.trim().isEmpty) {
      if (tempList != null) {
        courses = tempList;
        tempList = null;
        controller?.sink?.add(courses.length);
      }
    }
    courses = tempList
        .where(
            (course) => course.toLowerCase().contains(searchWord.toLowerCase()))
        .toList();
    controller?.sink?.add((courses.length == 0) ? -2 : courses.length);
  }

  checkCourses() {
    if (tempList != null) {
      courses = tempList;
      tempList = null;
    }
    if (courses.length == 0) controller?.sink?.add(0);
    int iterated = courses.length;
    controller?.sink?.add(-1);
    for (String course in courses) {
      List<Future<List<DownloadPaper>>> futures = [];
      futures.add(getFinalPapers(course));
      futures.add(getCtPapers(course));
      Future.wait(futures).then((data) {
        if (data[0].isEmpty && data[1].isEmpty) {
          courses.remove(course);
        }
        iterated--;
        if (iterated == 0) controller?.sink?.add(courses.length);
        return;
      });
    }
  }

  void query({bool check = false}) async {
    print("yo");
    var client = http.Client();
    try {
      var response = await client
          .get("$parentUrl$getCourseUrl", headers: {"Authorization": token});
      print("${response.statusCode} yay , ${response.body}");
      if (response.statusCode == 200) {
        Map jsonResponse = json.decode(response.body);
        for (Map courseObj in jsonResponse["course"]) {
          if (check) {
            List<Future<List<DownloadPaper>>> futures = [];
            futures.add(getFinalPapers(courseObj["coursename"]));
            futures.add(getCtPapers(courseObj["coursename"]));
            var data = await Future.wait(futures);
            if (data[0].isEmpty && data[1].isEmpty) continue;
          }
          courses.add(courseObj["coursename"]);
          ids.add(courseObj["_id"]);
        }
        controller.sink.add(courses.length);
      } else {
        print("ERROR");
        print(response.body);
        controller.sink.add(0);
      }
    } catch (e) {
      print("ERROR");
      print(e.toString());
      controller.sink.add(0);
    }
  }

  Future<List<String>> getSubjectCodes() async {
    var client = http.Client();
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

  addItemToBox(DownloadHistory item) async {
    DownloadHistoryAdapter().addItem(item);
    print("ADDING ${item.id}");;
  }

  Future<bool> alreadyDownloaded(String id) async {

    for (int i = 0; i < paperBox.getAll().length; i++) {
      print("CHECK $id ${paperBox.getById(i)}");
      if (paperBox.getById(i).id == id) {
        String filename = paperBox.getById(i).fileName;
        String dirloc = "/sdcard/download/srmpdf/";
        bool isExist = await File("$dirloc$filename").exists();
        print("$dirloc$filename exists $isExist");
        return isExist;
      }
    }

    return false;
  }

  Future<ValueListenable> getListenable() async {
    return paperBox.storage.listenable;
  }
}
