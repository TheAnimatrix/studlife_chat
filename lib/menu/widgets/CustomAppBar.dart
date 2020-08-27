import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {

  final Function menuClick;

  const CustomAppBar({Key key, @required this.menuClick}) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topRight,
        child: Padding(
            padding: EdgeInsets.only(right: 10, top: 5),
            child: IconButton(
              icon: Icon(Icons.menu),
              color: Colors.white,
              onPressed: widget.menuClick,
              iconSize: 30,
            )));
  }
}
