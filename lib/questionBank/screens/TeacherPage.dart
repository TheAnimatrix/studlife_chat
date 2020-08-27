import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:intl/intl.dart';
import 'package:studlife_chat/questionBank/models/PaperData.dart';
import 'package:studlife_chat/questionBank/persistent_models/PaperDataAdapter.dart';
import 'package:studlife_chat/questionBank/services/filePicker.dart';
import 'package:studlife_chat/questionBank/services/teacherAuth.dart';
import 'package:studlife_chat/questionBank/services/teacherLogic.dart';
import 'package:studlife_chat/questionBank/widgets/Left.dart';
import 'package:studlife_chat/questionBank/widgets/SwitchBox.dart';

import '../get_it.dart';

class TeacherPage extends StatefulWidget {
  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  bool ct = false;
  GlobalKey<FormState> _fileSubmitKey = GlobalKey();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  String sub_code;
  //sem
  String sem_month = "", sem_year = "";
  //ct
  String ct_month = "", ct_year = "", ct_num = "";
  //textControllers
  TextEditingController _monthDeptController = TextEditingController();
  TextEditingController _yearController = TextEditingController();
  TextEditingController _ctController = TextEditingController();
  TextEditingController _courseController = TextEditingController();
  List<String> subjectCodeSuggestions;

  bool selectingFile = false;
  String selectedFile = "";
  TeacherLogic logic = TeacherLogic();
  bool editSubjectCode = false;
  String subjectCodeHint = "Select Subject Code";
  String email;
  ScrollController _mainScrollController = ScrollController();

  _resetState() {
    setState(() {
      selectingFile = false;
      selectedFile = '';
      editSubjectCode = false;
      subjectCodeHint = "Select Subject Code";
      sem_month = "";
      sem_year = "";
      ct_month = "";
      ct_year = "";
      ct_num = '';
      _monthDeptController.clear();
      _yearController.clear();
      _ctController.clear();
      _courseController.clear();
      selectedFileFull = null;
    });
  }

  _toggleSubjectCodeInput(bool enable) {
    setState(() {
      if (enable) {
        editSubjectCode = true;
        subjectCodeHint = "Enter Subject Code";
      } else {
        editSubjectCode = false;
        subjectCodeHint = "Select Subject Code";
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //get the course list before the ui is displayed and show it when the first frame is displayed

    getIt<TeacherAuth>().getEmailFromSignedInUser().then((value) {
      this.email = value;
    });
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      logic.getSubjectCodes().then((value) {
        setState(() {
          subjectCodeSuggestions = List();
          subjectCodeSuggestions = value;
        });
      });
    });
  }

  _showSubjectPickerDialog(context) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            child: (subjectCodeSuggestions != null)
                ? _getListViewForSubjectDialog()
                : FutureBuilder<List<String>>(
                    future: logic.getSubjectCodes(),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Center(
                              child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: CircularProgressIndicator(),
                          ));
                        case ConnectionState.done:
                          subjectCodeSuggestions = snapshot.data;
                          return _getListViewForSubjectDialog();
                        default:
                          break;
                      }
                    }),
          );
        }).then((value) {
      if (value != null && value.length > 5 && value.length < 10) {
        this.sub_code = value;
        _courseController.text = sub_code;
      }
    });
  }

  _getListViewForSubjectDialog() {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (ctx, i) {
        if (subjectCodeSuggestions.length == 0) {
          return ListTile(
            contentPadding: EdgeInsets.all(10),
            title: Text("Options failed to load, try later"),
          );
        } else {
          if (i == subjectCodeSuggestions.length) {
            return Card(
              margin: EdgeInsets.all(8),
              elevation: 20,
              child: ListTile(
                onTap: () {
                  _toggleSubjectCodeInput(true);
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.all(8),
                title: Text("Subject code not listed?"),
              ),
            );
          }
          return Card(
            margin: EdgeInsets.all(8),
            elevation: 20,
            child: ListTile(
              onTap: () {
                Navigator.pop(context, subjectCodeSuggestions[i]);
              },
              contentPadding: EdgeInsets.all(8),
              title: Text("${subjectCodeSuggestions[i]}"),
            ),
          );
        }
      },
      itemCount: (subjectCodeSuggestions.length == 0)
          ? 1
          : subjectCodeSuggestions.length + 1,
    );
  }

  _showLoadingDialog(context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text("Uploading File.."),
                      )
                    ],
                  ),
                ),
              ),
            ));
  }

  _showErrorDialog(String error, context) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
              contentPadding: EdgeInsets.all(20),
              title: Text("Error"),
              content: Text("$error"),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("ok"))
              ],
            ));
  }

  String newFileName;
  Future<Map> _uploadFile(File file, context) async {
    String courseName = _courseController.text;
    bool isNewCourse = editSubjectCode;
    if (subjectCodeSuggestions.contains(courseName)) isNewCourse = false;
    try {
      if (ct) {
        newFileName = "$courseName\_$ct_month\_$ct_year\_$ct_num.pdf";
        _showLoadingDialog(context);
        try {
          var response = await logic.uploadFileWithDio(
              newFileName, courseName, false, file,
              newCourse: isNewCourse);
          Navigator.pop(context);
          if (response.statusCode == 200) {
            return {"error": false};
          } else {
            //_showErrorDialog("${response.toString()}", context);
            //return false
            return {"error": true, "message": "${response.toString()}"};
          }
        } on DioError catch (e) {
          print("ERROR UPLOADING ${e.toString()}");
          Navigator.pop(context);
          //_showErrorDialog("${e.toString()}", context);
          //return false;
          return {"error": true, "message": "${e.toString()}"};
        }
      } else {
        try {
          newFileName = "$courseName\_$sem_month\_$sem_year.pdf";
          _showLoadingDialog(context);
          var response = await logic.uploadFileWithDio(
              newFileName, courseName, true, file,
              newCourse: isNewCourse);
          Navigator.pop(context);
          if (response.statusCode == 200) {
            print('Success ${response.toString()}');
            return {"error": false, "message": ""};
          } else {
            //_showErrorDialog("${response.toString()}", context);
            return {"error": true, "message": "${response.toString()}"};
          }
        } catch (e) {
          print("ERROR UPLOADING ${e.toString()}");
          Navigator.pop(context);
          //_showErrorDialog("${e.toString()}", context);
          return {"error": true, "message": "${e.toString()}"};
        }
      }
    } catch (e) {
      return {"error": true, "message": "${e.toString()}"};
    }
  }

  _showMonthDialog(context, ctActive) {
    showMonthPicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(DateTime.now().year - 20),
            lastDate: DateTime.now())
        .then((value) {
      setState(() {
        if (ctActive) {
          this.ct_year = new DateFormat.y().format(value);
          _yearController.text = this.ct_year;
        } else {
          this.sem_month = new DateFormat.MMMM().format(value);
          _monthDeptController.text = sem_month;
          this.sem_year = new DateFormat.y().format(value);
          _yearController.text = this.sem_year;
        }

        _fileSubmitKey.currentState.validate();
      });
    });
  }

  File selectedFileFull = null;

  _selectFile() async {
    if (!_fileSubmitKey.currentState.validate()) return;

    print("you've made it CT:$ct SEM:${!ct}");

    setState(() {
      selectingFile = true;
    });
    File file = await getFile();
    if (file == null) {
      selectingFile = false;
      return;
    }
    print(file.uri.toString());
    selectedFileFull = file;
    setState(() {
      selectingFile = false;
      selectedFile = file.uri.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 0, 0),
            child: Text(
              "Teacher Panel",
              style: TextStyle(fontSize: 26, color: Colors.white),
            ),
          ),
          actions: <Widget>[
            RaisedButton(
                child: Text(
                  "Sign out",
                  style: TextStyle(color: Colors.white70),
                ),
                color: Colors.blueAccent,
                onPressed: () async {
                  await getIt<TeacherAuth>().logout();
                })
          ]),
      body: Form(
        child: ListView(
          controller: _mainScrollController,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Form(
                key: _fileSubmitKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "You are logged in as\n${getIt<TeacherAuth>().box.getById(0).emailAddress}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5)),
                                ),
                              ),
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: FlatButton(
                                    child: Text("View Papers"),
                                    onPressed: () {
                                      Navigator.pushNamed(context, "/listSubjects");
                                    },
                                  ))
                            ],
                          ),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Text("Upload Paper",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    SizedBox(
                      height: 20,
                    ),
                    Left(
                      child: Text(
                        "Type",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Left(
                      leftPadding: 40,
                      child: SwitchBox(
                        option1: "SEM",
                        option2: "CT",
                        bgColor: Colors.blueAccent,
                        textSize: 18,
                        shadowBlur: 8,
                        shadowColor: Color(0xFF000000).withAlpha(100),
                        //shadowColor: Color(0xFF0088FF).withAlpha(180),
                        onChanged: (changed) {
                          //false for sem, true for ct
                          if (changed) {
                            //ct
                            setState(() {
                              ct = true;
                              _monthDeptController.text = this.ct_month;
                              _yearController.text = this.ct_year;
                            });
                          } else {
                            //sem
                            setState(() {
                              ct = false;
                              _monthDeptController.text = this.sem_month;
                              _yearController.text = this.sem_year;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Left(
                      child: Text(
                        "Subject Code",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Card(
                        margin: EdgeInsets.fromLTRB(40, 0, 40, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                flex: 5,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                      hintText: subjectCodeHint),
                                  onChanged: (value) {
                                    this.sub_code = value;
                                  },
                                  controller: _courseController,
                                  readOnly: !editSubjectCode,
                                  onTap: () {
                                    if (!editSubjectCode)
                                      _showSubjectPickerDialog(context);
                                  },
                                  validator: (v) {
                                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v))
                                      return "Please enter a valid subject code";
                                    if (v.length < 5 || v.length > 8)
                                      return "Please enter a valid subject code";
                                    return null;
                                  },
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: FlatButton(
                                    onPressed: () {
                                      _toggleSubjectCodeInput(false);
                                    },
                                    child: Icon(Icons.refresh)),
                              )
                            ],
                          ),
                        )),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(38.0, 0, 38, 0),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            fit: FlexFit.loose,
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  elevation: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      readOnly: (!ct) ? true : false,
                                      decoration: InputDecoration(
                                          hintText: (!ct) ? "Month" : "Dept"),
                                      controller: _monthDeptController,
                                      onChanged: (changed) {
                                        if (ct) {
                                          print("changed $changed");
                                          this.ct_month = changed;
                                        }
                                      },
                                      validator: (v) {
                                        if (ct) {
                                          if (v.length <= 2) return "Invalid";
                                        } else {
                                          if (!(v.length >= 3 && v.length <= 9))
                                            return "Invalid";
                                        }
                                        return null;
                                      },
                                      onTap: () {
                                        if (ct) {
                                          return;
                                        } else {
                                          _showMonthDialog(context, ct);
                                          return;
                                        }
                                      },
                                    ),
                                  )),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  elevation: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: _yearController,
                                      readOnly: true,
                                      decoration:
                                          InputDecoration(hintText: "Year"),
                                      validator: (v) {
                                        if (v.length != 4) return "Invalid";

                                        return null;
                                      },
                                      onTap: () {
                                        if (ct) {
                                          _showMonthDialog(context, ct);
                                          return;
                                        } else {
                                          _showMonthDialog(context, ct);
                                          return;
                                        }
                                      },
                                    ),
                                  )),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: AnimatedOpacity(
                                duration: Duration(milliseconds: 500),
                                opacity: (ct) ? 1 : 0.2,
                                child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    elevation: 10,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: TextFormField(
                                        keyboardType: TextInputType.number,
                                        controller: _ctController,
                                        maxLength: 1,
                                        enabled: ct,
                                        onChanged: (changed) {
                                          var value = int.tryParse(changed);
                                          if (value != null) {
                                            this.ct_num = value.toString();
                                          } else {
                                            _ctController.text = '';
                                          }
                                        },
                                        validator: (v) {
                                          if (ct) {
                                            var value = int.tryParse(v);
                                            if (value == null ||
                                                value <= 0 ||
                                                value > 4) return "Invalid";
                                          }
                                          return null;
                                        },
                                        decoration:
                                            InputDecoration(hintText: "CT"),
                                      ),
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Left(
                      child: RichText(
                        text: TextSpan(
                          text: '',
                          style: TextStyle(
                              fontFamily: 'PS',
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                              fontSize: 18,
                              decoration: TextDecoration.none),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'File',
                                style: TextStyle(
                                    fontFamily: 'PS',
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                    fontSize: 18,
                                    decoration: TextDecoration.none)),
                            TextSpan(
                                text: "   (only .pdf's less than 2mb)",
                                style: TextStyle(
                                  fontFamily: 'PS',
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white54,
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Left(
                        rightPadding: 40,
                        child: RaisedButton(
                          color: Colors.blueAccent,
                          elevation: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          onPressed: () {
                            if (selectedFile.isNotEmpty) {
                              _uploadFile(selectedFileFull, context)
                                  .then((value) {
                                //fixes duplicate subject code in suggestion list.
                                if (!value["error"]) {
                                  bool contained = false;
                                  for (String subjectCode
                                      in subjectCodeSuggestions) {
                                    if (subjectCode.trim().toLowerCase() ==
                                        _courseController.text
                                            .trim()
                                            .toLowerCase()) contained = true;
                                  }
                                  if (!contained)
                                    subjectCodeSuggestions
                                        .add(_courseController.text);
                                }
                                logic.addItemToBox(PaperHistoryItem(
                                    ownerEmail: email,
                                    paperName: "$newFileName"));
                                _resetState();
                                showModalBottomSheet<dynamic>(
                                    isScrollControlled: true,
                                    backgroundColor: value["error"]
                                        ? Colors.red
                                        : Colors.green,
                                    builder: (context) {
                                      return SizedBox(
                                        height: 300,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: value["error"]
                                                    ? Icon(Icons.error,
                                                        color: Colors.white)
                                                    : Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                      ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(value["error"]
                                                    ? "${value["message"]}"
                                                    : "SuccessFully Uploaded Paper"),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    context: context);
                              });
                            } else
                              _selectFile();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: (!selectingFile)
                                ? (selectedFile.isEmpty)
                                    ? Text("Select file")
                                    : Row(
                                        children: <Widget>[
                                          Flexible(
                                              flex: 6,
                                              child: Text("$selectedFile")),
                                          Flexible(
                                              flex: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(Icons.file_upload),
                                              ))
                                        ],
                                      )
                                : CircularProgressIndicator(),
                          ),
                        )),
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectingFile = false;
                          selectedFile = '';
                          selectedFileFull = null;
                        });
                      },
                      child: Left(
                        topPadding: 10,
                        child: AnimatedOpacity(
                          opacity: (selectedFile.isNotEmpty) ? 1 : 0,
                          duration: Duration(milliseconds: 500),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            height: (selectedFile.isNotEmpty) ? 30 : 0,
                            child: Row(
                              children: <Widget>[
                                Flexible(
                                  child: Icon(Icons.cancel),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("Remove"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Left(
                      topPadding: 10,
                      bottomPadding: 20,
                      child: Text("History", style: TextStyle(fontSize: 18)),
                    ),
                    _buildHistoryListView(email),
                    SizedBox(
                      height: 60,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildHistoryListView(email) {
    var formatter = new DateFormat("EEEE, MMMM-d yyyy 'at' hh:mm aaa");
    return ValueListenableBuilder<Map<String,dynamic>>(
                valueListenable: logic.getListenable(),
                builder: (context, Map<String,dynamic> box, widget) {
                  var adapter = PaperHistoryItemAdapter();
                  if (box.length <= 0)
                    return Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text("No history"),
                    );
                  List<PaperHistoryItem> filtered = List();
                  List<PaperHistoryItem> all = adapter.getAll();
                  for (int i = 0; i < all.length; i++) {
                    PaperHistoryItem item = all.elementAt(i);
                    if (item.ownerEmail == email) filtered.add(item);
                  }
                  if (filtered.length <= 0)
                    return Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text("No history"),
                    );

                  return ListView.builder(
                      shrinkWrap: true,
                      controller: _mainScrollController,
                      itemBuilder: (ctx, i) {
                        return Card(
                            elevation: 20,
                            margin: EdgeInsets.fromLTRB(50, 0, 50, 20),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(8),
                              title: Text(
                                  filtered[filtered.length - i - 1].paperName),
                              subtitle: Text(formatter.format(DateTime.parse(
                                  filtered[filtered.length - i - 1]
                                      .dateCreated))),
                            ));
                      },
                      itemCount: filtered.length);
                },
              );
  }
}
