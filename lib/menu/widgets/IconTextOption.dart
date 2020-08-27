import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:studlife_chat/constants/themes.dart';

class IconTextOption extends StatefulWidget {
  final IconText option;
  final bg;

  IconTextOption(
      {Key key, this.option, this.bg = ThemeConstants.PURPLE_GRADIENT})
      : super(key: key);

  @override
  _IconTextOptionState createState() => _IconTextOptionState();
}

class _IconTextOptionState extends State<IconTextOption> {
  Color _computed(bool isWhite) {
    if (isWhite) return ThemeConstants.MENU_NOT_SELECTED;
    return ((this.widget.bg == Colors.transparent)
        ? ThemeConstants.MENU_NOT_SELECTED
        : (this.widget.bg as LinearGradient).colors[0].computeLuminance() > 0.5
            ? ThemeConstants.MENU_NOT_SELECTED
            : Colors.white);
  }

  GlobalKey _iconTextKey = GlobalKey();

  double WIDTH = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (_iconTextKey.currentContext != null)
        WIDTH =
            (_iconTextKey.currentContext.findRenderObject() as RenderBox)
                .size
                .width + 15;
      else
        WIDTH = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 140),
          height: 55,
          width: (widget.option.selected)?WIDTH:0,
          decoration: BoxDecoration(
                  gradient: widget.option.selectedGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                      BoxShadow(
                          blurRadius: 9,
                          color: Color(0xFF7B6DFF).withOpacity(0.81))
                    ]),
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
          child: Row(
            
                
            key: _iconTextKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.option.icon,
                  color: (widget.option.selected)
                      ? Colors.white
                      : (widget.option.iconColor != null)
                          ? widget.option.iconColor
                          : _computed(!widget.option.selected)),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.option.text,
                    style: TextStyle(
                        color: (widget.option.selected)
                            ? Colors.white
                            : (widget.option.textColor != null)
                                ? widget.option.textColor
                                : _computed(!widget.option.selected),
                        fontSize: 17),
                  ))
            ],
          ),
        ),
      ],
    );
  }
}

class IconText {
  final IconData icon;
  final Color iconColor;
  final LinearGradient selectedGradient;
  final String text;
  final bool selected;
  final Color textColor;

  IconText(
      {this.textColor,
      this.iconColor,
      this.selectedGradient = ThemeConstants.PURPLE_GRADIENT,
      this.icon,
      this.text,
      this.selected = false});
}
