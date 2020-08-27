import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:studlife_chat/questionBank/models/CourseArguements.dart';
import 'package:studlife_chat/questionBank/models/Paper.dart';
import 'package:studlife_chat/questionBank/services/studentLogic.dart';

class BrowserCoursePage extends StatefulWidget {
  @override
  _BrowserCoursePageState createState() => _BrowserCoursePageState();
}

class _BrowserCoursePageState extends State<BrowserCoursePage> {
  Logic logicClass;
  String pageName = "Courses";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    logicClass = Logic();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      logicClass.query();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    logicClass.dispose();
  }

  bool switchVal = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 21,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Color(0xFFFFFFFF)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Courses", style: TextStyle(fontSize: 30)),
        ),
        body: StreamBuilder<int>(
            stream: logicClass.controller.stream,
            initialData: -1,
            builder: (context, snapshot) {
              if (snapshot.data < 0&&snapshot.data!=-2) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.data == 0) { //-2 is case when search results are empty
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("No data",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 20),
                    FlatButton(
                      child: Icon(
                        Icons.refresh,
                        size: 40,
                      ),
                      onPressed: () {
                        switchVal = false;
                        logicClass.query();
                        logicClass.controller?.sink?.add(-1);
                      },
                    )
                  ],
                ));
              } else {
                return Column(
                  children: <Widget>[
                    // Align(
                    //   alignment: Alignment.topLeft,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(20.0),
                    //     child: Row(
                    //       children: <Widget>[
                    //         FlatButton(
                    //             child: Icon(
                    //               Icons.keyboard_arrow_left,
                    //               size: 40,
                    //             ),
                    //             onPressed: () {
                    //               Navigator.pop(context);
                    //             }),
                    //         Text(
                    //           pageName,
                    //           style: TextStyle(fontSize: 30),
                    //           textAlign: TextAlign.left,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Row(
                      children: <Widget>[
                        SizedBox(width: 20),
                        Text("filter: Remove subjects with no papers uploaded",
                            style: TextStyle(color: Colors.white70)),
                        Switch(
                            value: switchVal,
                            onChanged: (val) {
                              setState(() {
                                switchVal = val;
                                if (switchVal) {
                                  logicClass.checkCourses();
                                } else {
                                  logicClass.query();
                                  logicClass.courses.clear();
                                  logicClass.controller?.sink?.add(-1);
                                }
                              });
                            }),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16,0,16,0),
                      child: TextField(
                        decoration:InputDecoration(
                          hintText: "Search",
                          prefixIcon: Icon(Icons.search)
                        ),
                        onChanged: (value)
                        {
                          print("VALUE $value");
                          logicClass.filterCourses(value);
                        },
                      ),
                    ),
                    (snapshot.data!=-2)?Expanded(
                      child: ListView.builder(
                        itemBuilder: (ctx, index) {
                          return _buildItem(ctx, index);
                        },
                        itemCount: logicClass.courses.length,
                      ),
                    ): Expanded(
                                          child: Center(
                        child: Text("No data",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                );
              }
            }),
      ),
    );
  }

  _buildItem(ctx, index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 6.0),
      child: Card(
        elevation: 20,
        child: InkWell(
            onTap: () {
              _showItemsToDownloadInNewPageIfExistsOtherwiseDialog(
                  context, index);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text("${logicClass.courses[index]}"),
              ),
            )),
      ),
    );
  }

  _showItemsToDownloadInNewPageIfExistsOtherwiseDialog(context, index) async {
    List<DownloadPaper> finalPapers = [];
    List<DownloadPaper> ctPapers = [];
    List<Future> futures = [];
    try {
      _showLoadingDialog(context);
      futures.add(logicClass.getFinalPapers(logicClass.courses[index]));
      futures.add(logicClass.getCtPapers(logicClass.courses[index]));
      var data = await Future.wait(futures);
      Navigator.pop(context);
      finalPapers = data[0];
      ctPapers = data[1];
      if (finalPapers.isEmpty && ctPapers.isEmpty) {
        _showNoDataDialog(context, index);
      } else {
        Navigator.pushNamed(context, "/listDownloadPapers",
            arguments: CourseArguements(
                ctPapers: ctPapers,
                finalPapers: finalPapers,
                courseName: logicClass.courses[index]));
      }
    } catch (e) {
      Navigator.pop(context);
      print("ERROR ${e.toString}");
      _showNoDataDialog(context, index,
          error: "${e.toString()}", remove: false);
    }
  }

  _showLoadingDialog(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) {
          return WillPopScope(
            onWillPop: () {
              return Future.value(false);
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: Dialog(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Text("Loading",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 20)),
                    SizedBox(
                      height: 10,
                    ),
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
                backgroundColor: Colors.white10,
              ),
            ),
          );
        });
  }

  _showNoDataDialog(context, index, {String error = "", bool remove = false}) {
    showDialog(
        context: context,
        builder: (ctx) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: AlertDialog(
              title: Text((error == "") ? 'No data' : '$error'),
              backgroundColor: Colors.white10,
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    "close",
                  ),
                  onPressed: () {
                    if (remove) logicClass.remove(index);
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          );
        });
  }

  // _showDownloadDialog(context, index) {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         return FutureBuilder(
  //           builder: (ctx, snapshot) {
  //             switch (snapshot.connectionState) {
  //               case ConnectionState.active:
  //                 break;
  //               case ConnectionState.done:
  //                 if (snapshot.data.length <= 0) {
  //                   return BackdropFilter(
  //                     filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
  //                     child: AlertDialog(
  //                       title: Text('No data'),
  //                       backgroundColor: Colors.black45,
  //                       actions: <Widget>[
  //                         FlatButton(
  //                           child: Text(
  //                             "close",
  //                           ),
  //                           onPressed: () {
  //                             Navigator.pop(context);
  //                           },
  //                         )
  //                       ],
  //                     ),
  //                   );
  //                 }

  //                 return Dialog(
  //                   child: ListView.builder(
  //                     itemBuilder: (ctx, index2) {
  //                       return Card(
  //                         margin: EdgeInsets.all(15),
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(8.0),
  //                           child: Text(snapshot.data[index2]),
  //                         ),
  //                         elevation: 20,
  //                       );
  //                     },
  //                     shrinkWrap: true,
  //                     itemCount: snapshot.data.length,
  //                   ),
  //                 );
  //                 break;
  //               case ConnectionState.waiting:
  //                 return SimpleDialog(children: <Widget>[
  //                   Center(
  //                       child: Column(
  //                     children: <Widget>[
  //                       CircularProgressIndicator(),
  //                     ],
  //                   ))
  //                 ]);
  //                 break;
  //               case ConnectionState.none:
  //                 break;
  //             }
  //           },
  //           future: logicClass.getFinalPapers("${logicClass.courses[index]}"),
  //         );
  //       });
  // }
}
