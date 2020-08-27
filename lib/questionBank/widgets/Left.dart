
import 'package:flutter/material.dart';

class Left extends StatelessWidget {

  final Widget child;
  final double leftPadding, topPadding, bottomPadding, rightPadding;
  Left({this.child,this.leftPadding=50,this.topPadding=0,this.bottomPadding=0,this.rightPadding=0});

  @override
  Widget build(BuildContext context) {
    return Align(child: Padding(
      padding: EdgeInsets.fromLTRB(leftPadding, topPadding, rightPadding, bottomPadding),
      child: child,
    ),alignment: Alignment.centerLeft,);
  }
}