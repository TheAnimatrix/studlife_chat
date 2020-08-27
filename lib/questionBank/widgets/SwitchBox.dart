import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SwitchBox extends StatefulWidget {
  @override
  _SwitchBoxState createState() => _SwitchBoxState();

  String option1, option2;
  Function(bool) onChanged;
  Duration duration;
  double textSize;
  double shadowBlur;
  Color bgColor, selectedColor, shadowColor, textColor, textColorSelected;
  int defaultOption;
  Key key;

  SwitchBox(
      {this.key,this.option1,
      this.option2,
      this.onChanged,
      this.duration = const Duration(seconds: 2),
      this.textSize = 24,
      this.shadowBlur = 12,
      this.bgColor = Colors.amberAccent,
      this.selectedColor = Colors.black38,
      this.shadowColor = Colors.black54,
      this.textColor = Colors.black87,
      this.textColorSelected = Colors.white,
      this.defaultOption = 0}) : super(key:key);
}

class _SwitchBoxState extends State<SwitchBox> {
  bool choice = false; //false for L, true for R

  double leftChoice = 57;
  double rightChoice = 49;
  GlobalKey option1Key = GlobalKey();
  GlobalKey option2Key = GlobalKey();
  Color bgColor2;
  int preAlpha;
  double shadowBlur;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bgColor2 = widget.bgColor;
    choice = !(widget.defaultOption == 0);
    preAlpha = widget.shadowColor.alpha;
    shadowBlur = widget.shadowBlur;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (option2Key.currentContext == null) return;
      if (option1Key.currentContext == null) return;
      print("${option2Key.currentContext.size.width}");
      print("${option1Key.currentContext.size.width}");
      setState(() {
        leftChoice = option1Key.currentContext.size.width + 13;
        rightChoice = option2Key.currentContext.size.width + 13;

        print("R:$rightChoice L:$leftChoice");
      });
    });
  }

  @override
  void didUpdateWidget(SwitchBox oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (option2Key.currentContext == null) return;
      if (option1Key.currentContext == null) return;
      print("${option2Key.currentContext.size.width}");
      print("${option1Key.currentContext.size.width}");
      setState(() {
        leftChoice = option1Key.currentContext.size.width + 13;
        rightChoice = option2Key.currentContext.size.width + 13;

        print("R:$rightChoice L:$leftChoice");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          choice = !choice;
          widget.onChanged(choice);
        });
      },
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onHover: (hover) {
        print("hovering $hover");
        setState(() {
          if (hover) {
            shadowBlur = widget.shadowBlur + 12;
            widget.shadowColor.withAlpha(preAlpha - 60);
          } else {
            shadowBlur = widget.shadowBlur;
            widget.shadowColor = widget.shadowColor.withAlpha(preAlpha);
          }
        });
      },
      onHighlightChanged: (hl) {
        print("highlight changed $hl");
        setState(() {
          if (!kIsWeb) {
            if (Platform.isAndroid || Platform.isFuchsia || Platform.isIOS) {
              if (hl) {
                shadowBlur = widget.shadowBlur + 12;
                widget.shadowColor.withAlpha(preAlpha - 60);
                bgColor2 = Color.alphaBlend(
                    Colors.white.withAlpha(20), widget.bgColor);
              } else {
                shadowBlur = widget.shadowBlur;
                widget.shadowColor = widget.shadowColor.withAlpha(preAlpha);
                bgColor2 = widget.bgColor;
              }
            } else {
              if (hl) {
                bgColor2 = Color.alphaBlend(
                    Colors.white.withAlpha(150), widget.bgColor);
              } else {
                bgColor2 = widget.bgColor;
              }
            }
          } else {
            if (hl) {
              bgColor2 =
                  Color.alphaBlend(Colors.white.withAlpha(150), widget.bgColor);
            } else {
              bgColor2 = widget.bgColor;
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        decoration: BoxDecoration(
            color: bgColor2,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  blurRadius: shadowBlur,
                  offset: Offset(0, 6),
                  color: widget.shadowColor)
            ]),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                curve: Curves.elasticOut,
                duration: widget.duration,
                top: 0,
                bottom: 0,
                left: (choice) ? leftChoice : 0,
                right: (choice) ? 0 : rightChoice,
                child: Container(
                  decoration: BoxDecoration(
                      color: widget.selectedColor,
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "${widget.option1}",
                      key: option1Key,
                      style: TextStyle(
                          color: (choice)
                              ? widget.textColor
                              : widget.textColorSelected,
                          decoration: TextDecoration.none,
                          fontSize: widget.textSize),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "${widget.option2}",
                      key: option2Key,
                      style: TextStyle(
                          color: (!choice)
                              ? widget.textColor
                              : widget.textColorSelected,
                          decoration: TextDecoration.none,
                          fontSize: widget.textSize),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
