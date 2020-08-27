import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:studlife_chat/auth/changeNotifiers/AuthService.dart';
import 'package:studlife_chat/bloc/rooms.dart';
import 'package:studlife_chat/bloc_http/rooms.dart';
import 'package:studlife_chat/chat/screens/chatRoom.dart';
import 'package:studlife_chat/menu/screens/menu_demo.dart';
import 'package:studlife_chat/questionBank/get_it.dart';
import 'package:studlife_chat/questionBank/playg.dart';
import 'package:studlife_chat/questionBank/screens/AuthPage.dart';
import 'package:studlife_chat/questionBank/screens/BrowserCoursePage.dart';
import 'package:studlife_chat/questionBank/screens/BrowserFileByCourseAndDownloadPage.dart';
import 'package:studlife_chat/auth/wrapper.dart';

import 'chat/bloc/chat.dart';
import 'constants/themes.dart';

void main() {
  setup();
  runApp(
      BlocProvider(lazy: false, create: (ctx) => ChatBloc(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QB Chat',
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
        '/listSubjects': (context) => BrowserCoursePage(),
        '/listDownloadPapers': (context) => BrowseFileByCourseAndDownloadPage(),
        '/testing': (context) => Playground(),
        '/chatroom': (context) => ChatRoom(key: UniqueKey()),
        '/rooms': (context) => StreamProvider.value(
              child: Wrapper(),
              value: AuthService().user,
            )
      },
      initialRoute: '/rooms',
    );
  }
}
