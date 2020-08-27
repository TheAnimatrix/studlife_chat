import 'package:flutter/material.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';

class LoaderScreen extends StatefulWidget {
  
  @override
  _LoaderScreenState createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {

  BallPulseIndicator indicatorToShow;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    indicatorToShow = BallPulseIndicator();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    for ( AnimationController a in indicatorToShow.animation())
    {
      a.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        child: Center(
          child: Loading(indicator: indicatorToShow, size: 100.0,color: Colors.amberAccent),
        ),
      );
  }
}