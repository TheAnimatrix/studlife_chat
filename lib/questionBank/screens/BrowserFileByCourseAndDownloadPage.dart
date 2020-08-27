import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studlife_chat/questionBank/models/CourseArguements.dart';
import 'package:studlife_chat/questionBank/models/DownloadHistory.dart';
import 'package:studlife_chat/questionBank/models/Paper.dart';
import 'dart:io' as io;

import 'package:studlife_chat/questionBank/services/studentLogic.dart';
import 'package:studlife_chat/questionBank/widgets/Left.dart';
import 'package:studlife_chat/questionBank/widgets/SwitchBox.dart';
class BrowseFileByCourseAndDownloadPage extends StatefulWidget {
  @override
  _BrowseFileByCourseAndDownloadPageState createState() =>
      _BrowseFileByCourseAndDownloadPageState();
}

class _BrowseFileByCourseAndDownloadPageState
    extends State<BrowseFileByCourseAndDownloadPage> {
  bool isCt = false;
  bool isDownloading = false;
  String token =
      "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1ZTk4OTQ0MjZiODcxMzAwMTdiOTFmNTAiLCJpYXQiOjE1ODcwNTc3MzB9.2rwQIP-zNJYlniV6HtZWkTOcqrz-Y_OFNvqQn-6fmcw";

  String parentUrl = "https://studlife-srm.herokuapp.com/";
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Logic logic;
  List<int> tempCtIndices, tempFinalIndices;

  Future<bool> _checkPermission() async {
    var status = await Permission.storage.status;
    if (status.isUndetermined) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    }

    if (status.isRestricted) {
      return false;
    }
    return false;
  }

  StreamController progressController = StreamController.broadcast();

// for a file
  Future<void> downloadFile(
      {String url,
      String downloadId,
      header,
      int index,
      String filename,
      bool downloaded,
      BuildContext context}) async {
    String dirloc = "";
    dirloc = "/sdcard/download/srmpdf/";

    if (downloaded) {
      var data = await OpenFile.open("$dirloc$filename");
      if (data.type == ResultType.done) return;
    }

    _showDownloadingDialog(context);

    Dio dio = Dio();
    isDownloading = true;

    print("$dirloc");

    print(url);

    try {
      // if (!(await Directory(dirloc).exists())) await Directory(dirloc).create();
      FileUtils.mkdir([dirloc]);
      Response response = await dio.download(url, "$dirloc$filename",
          lengthHeader: 'x-goog-stored-content-length',
          onReceiveProgress: (receivedBytes, totalBytes) {
        // setState(() {
        //   isDownloading = true;

        // });
        if (progressController == null || progressController.isClosed)
          progressController = StreamController();
        int prog = ((receivedBytes / totalBytes) * 100).toInt();
        if (prog <= 100)
          progressController.add(((receivedBytes / totalBytes) * 100));
        if (prog >= 100) {
          progressController.add((99).toDouble());
        }
        String progress =
            ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
        print("PROGRESS $progress");
      }, options: Options(headers: header, validateStatus: (s) => true));


      if (response.statusCode == 200) {
        progressController.add((100).toDouble());
        logic.addItemToBox(DownloadHistory(id: downloadId,fileName: filename));
        //pass i here and set the item downloaded
        setState(() {
          if (url.contains("finalpaper")) {
            tempFinalIndices.add(index);
          } else {
            tempCtIndices.add(index);
          }
        });
      } else {
        progressController.add(-10.0);
      }

      
      progressController?.close();
    } catch (e) {
      print("OOF FILE $e");
      
      progressController?.close();
    }

    isDownloading = false;
    // setState(() {
    // });
  }

  @override
  void dispose() {
    super.dispose();
    progressController?.close();
    logic.dispose();
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        final CourseArguements args = ModalRoute.of(context).settings.arguments;
        isCt = (args.ctPapers.isNotEmpty);
      });
    });
    tempCtIndices = [];
    tempFinalIndices = [];
    logic = Logic();
  }

  @override
  void didUpdateWidget(BrowseFileByCourseAndDownloadPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        final CourseArguements args = ModalRoute.of(context).settings.arguments;
        isCt = (args.ctPapers.isNotEmpty);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final CourseArguements args = ModalRoute.of(context).settings.arguments;
    final String courseName = args.courseName;
    final List<DownloadPaper> ctPapers = args.ctPapers;
    final List<DownloadPaper> finalPapers = args.finalPapers;
    final bool initialChoice = (args.ctPapers.isNotEmpty);
    for (DownloadPaper paper in finalPapers) print("${paper.toString()}");

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 45,
          ),
          Left(
              leftPadding: 12,
              child: FlatButton(
                child: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              )),
          Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
            width: double.infinity,
            color: Colors.blueAccent,
            child: Padding(
              padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: Text(
                "$courseName",
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Flexible(
                flex: 1,
                child: Row(
                  children: <Widget>[
                    Left(
                        child: Text(
                      "Files",
                      style: TextStyle(color: Colors.white, fontSize: 26),
                      textAlign: TextAlign.start,
                    )),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 40, 0),
                  child: SwitchBox(
                    option1: "SEM",
                    option2: "CT",
                    defaultOption: ((initialChoice) ? 1 : 0),
                    bgColor: Colors.blueAccent,
                    textSize: 18,
                    shadowBlur: 8,
                    shadowColor: Color(0xFF000000).withAlpha(100),
                    //shadowColor: Color(0xFF0088FF).withAlpha(180),
                    onChanged: (changed) {
                      //false for sem, true for ct
                      setState(() {
                        isCt = !isCt;
                      });
                    },
                  )),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Flexible(
            fit: FlexFit.loose,
            //remove intrinsic top padding list
            child: Stack(
              children: <Widget>[
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (ctx, i) {
                      Color boxColor = Colors.grey[800];
                      IconData dl_icon = Icons.cloud_download;
                      if (isCt) {
                        if (ctPapers.length == 0)
                          return _noDataCard(ctx, courseName);
                        if (ctPapers[i].downloaded ||
                            tempCtIndices.contains(i)) {
                          boxColor = Colors.green;
                          dl_icon = Icons.cloud_done;
                        }
                      } else {
                        if (finalPapers.length == 0)
                          return _noDataCard(ctx, courseName);
                        if (finalPapers[i].downloaded ||
                            tempFinalIndices.contains(i)) {
                          boxColor = Colors.green;
                          dl_icon = Icons.cloud_done;
                        }
                      }

                      bool downloaded = (isCt)
                          ? (ctPapers[i].downloaded ||
                              tempCtIndices.contains(i))
                          : (finalPapers[i].downloaded ||
                              tempFinalIndices.contains(i));

                      return Card(
                        margin: EdgeInsets.all(12),
                        elevation: 20,
                        color: boxColor,
                        child: ListTile(
                          onTap: () async {
                            print("$isCt");
                            if (isDownloading) {
                              _showProgressDialog(context);
                            } else {
                              //isDownloading = true;
                              bool storage = await _checkPermission();
                              if (!storage) {
                                showDialog(
                                    context: context,
                                    builder: (ctx) => SimpleDialog(
                                          contentPadding: EdgeInsets.all(20),
                                          children: <Widget>[
                                            Center(
                                                child: Text(
                                                    "Cannot download as storage permissions have been denied, check android settings"))
                                          ],
                                        ));
                                return;
                              }
                              // final directory =
                              //     await getExternalStorageDirectory();
                              // var _localPath = directory.path +
                              //     Platform.pathSeparator +
                              //     'Download';
                              // print("FULL PATH $_localPath");

                              // final savedDir = Directory(_localPath);
                              // bool hasExisted = await savedDir.exists();
                              // if (!hasExisted) {
                              //   savedDir.create();
                              // }
                              String fileName =
                                  (isCt) ? ctPapers[i].id : finalPapers[i].id;
                              String fileName2 = (isCt)
                                  ? ctPapers[i].fileName
                                  : finalPapers[i].fileName;
                              bool downloaded = (isCt)
                                  ? (ctPapers[i].downloaded ||
                                      tempCtIndices.contains(i))
                                  : (finalPapers[i].downloaded ||
                                      tempFinalIndices.contains(i));
                              String url =
                                  '$parentUrl/download/${(isCt) ? "ct" : "finalpaper"}/$fileName';
                              try {
                                downloadFile(
                                    url: url,
                                    filename: fileName2,
                                    header: {
                                      "Authorization": token,
                                      HttpHeaders.acceptEncodingHeader: "*"
                                    },
                                    index: i,
                                    downloadId: fileName,
                                    downloaded: downloaded,
                                    context: context);
                              } catch (e) {
                                print("FLUTTER DOWNLOAD ERR ${e.toString()}");
                              }
                            }
                          },
                          contentPadding: EdgeInsets.fromLTRB(40, 20, 40, 20),
                          title: (isCt)
                              ? Text("${ctPapers[i].fileName}")
                              : Text("${finalPapers[i].fileName}"),
                          trailing: Icon(dl_icon),
                          subtitle: Column(
                            children: <Widget>[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    "Type: ${(isCt) ? 'cycle test paper' : 'final paper'}"),
                              ),
                              (downloaded)
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Downloaded, tap to open"))
                                  : SizedBox.shrink()
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: isCt
                        ? (ctPapers.length == 0) ? 1 : ctPapers.length
                        : (finalPapers.length == 0) ? 1 : finalPapers.length,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 0)),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 3,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  _showDownloadingDialog(context) {
    if (progressController == null || progressController.isClosed)
      progressController = StreamController.broadcast();
    showDialog(
        context: context,
        builder: (ctx) {
          return StreamBuilder<Object>(
              stream: progressController.stream,
              initialData: null,
              builder: (context, snapshot) {
                if(snapshot.data==-10)
                {
                  return AlertDialog(
                    title:Text("Error Downloading File"),
                    content: Text("file could not be downloaded due to Network/Server Error please try again later"),
                    contentPadding: EdgeInsets.all(20),
                    actions: [
                      FlatButton(child:Text("close"),onPressed: () {Navigator.pop(context);},)
                    ],
                  );
                }
                return AlertDialog(
                  title: Text(
                      "${(snapshot.data == 100) ? 'Downloaded' : 'Downloading...'}"),
                  contentPadding: EdgeInsets.all(20),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(value: snapshot.data),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                          "Downloading ${(snapshot.data == null) ? 0 : (snapshot.data as double).toInt()}%"),
                      SizedBox(
                        height: 15,
                      ),
                      Text("Check your downloads folder once done")
                    ],
                  ),
                  actions: <Widget>[
                    FlatButton(
                        child: Text(
                          "${(snapshot.data == 100) ? 'Finished' : 'Continue in background'}",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                  ],
                );
              });
        });
  }

  _showProgressDialog(context) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Please wait.. one download at a time"),
            actions: <Widget>[
              FlatButton(
                  child: Text("Ok.. i'm waiting"),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          );
        });
  }

  _noDataCard(context, courseName) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 20,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(40, 20, 40, 20),
        title: Text(
            "No Papers available for ${isCt ? 'cycle test' : 'final exam'} of $courseName"),
        subtitle: Text("Consult your teacher for new uploads"),
      ),
    );
  }
}
