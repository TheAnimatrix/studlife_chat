import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:studlife_chat/questionBank/widgets/SwitchBox.dart';

class Playground extends StatefulWidget {
  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SwitchBox(
              option1: "SEM",
              option2: "CT",
              bgColor: Colors.white10,
              textColor: Colors.white38,
              onChanged: (changed) {
                //false left, true right
                print("changed $changed");
              },
            ),
            SizedBox(
              height: 20,
            ),
            SwitchBox(
              option1: "SEM",
              option2: "CT",
              textSize: 21,
              bgColor: Colors.red[500],
              textColor: Colors.white70,
              onChanged: (changed) {
                //false left, true right
                print("changed $changed");
              },
            ),
            SizedBox(
              height: 20,
            ),
            SwitchBox(
              option1: "CT",
              option2: "SEM",
              textSize: 18,
              bgColor: Colors.blue,
              duration: Duration(seconds: 1),
              onChanged: (changed) {
                //false left, true right
                print("changed $changed");
              },
            ),
          ],
        ),
      ),
    );
  }
}

