import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:studlife_chat/questionBank/playg.dart';
import 'package:studlife_chat/questionBank/screens/AuthPage.dart';
import 'package:studlife_chat/questionBank/screens/BrowserCoursePage.dart';
import 'package:studlife_chat/questionBank/screens/BrowserFileByCourseAndDownloadPage.dart';
import 'package:studlife_chat/auth/wrapper.dart';
import 'get_it.dart';
import 'persistent_models/AuthenticatedUserAdapter.dart';
import 'persistent_models/DownloadHistoryAdapter.dart';
import 'persistent_models/PaperDataAdapter.dart';

Future<void> main() async {
  // var path = Directory.current.path;
  // Hive
  //   ..init(path);
  await GetStorage.init();
  setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        accentColor: Colors.amberAccent,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'PS',
            ),
        primaryTextTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'PS',
            ),
        accentTextTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'PS',
            ),
      ),
      routes: {
        '/signup': (context) => SignUpPage(),
        '/wrapper': (context) => Wrapper(),
        '/listSubjects': (context) => BrowserCoursePage(),
        '/listDownloadPapers': (context) => BrowseFileByCourseAndDownloadPage(),
        '/testing': (context) => Playground()
      },
      initialRoute: '/wrapper',
    );
  }
}
