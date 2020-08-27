import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studlife_chat/auth/changeNotifiers/AuthService.dart';
import 'package:studlife_chat/constants/themes.dart';
import 'package:studlife_chat/menu/widgets/CustomAppBar.dart';
import 'package:studlife_chat/menu/widgets/IconTextOption.dart';
import 'package:websafe_svg/websafe_svg.dart';

class MenuWidget extends StatefulWidget {
  final Function searchCallback;
  final Function menuCallback;
  final Function roomCallback;
  final Function(BuildContext ctx, ScrollController _controller) builder;
  final Widget child;
  final bool onlyMenu;
  final String menuTitle;

  const MenuWidget(
      {Key key,
      this.searchCallback,
      this.menuCallback,
      this.roomCallback,
      @required this.builder,
      this.child,
      this.onlyMenu = false,
      this.menuTitle, })
      : super(key: key);

  @override
  _MenuWidgetState createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget>
    with SingleTickerProviderStateMixin {
  double _menuHeight = 140;
  ScrollController _listController = ScrollController();
  double MENU_SHADOW_THRESHOLD = 20;
  ValueNotifier<double> shadowAnimate = ValueNotifier<double>(0.0);
  ValueNotifier isShown = ValueNotifier(false);
  ValueNotifier isSearchClicked = ValueNotifier(false);
  AnimationController _shadowAnimation;
  Animation _shadowAnim;
  bool shadowForward = false;

  @override
  void initState() {
    super.initState();
    if (widget.onlyMenu) _menuHeight = 100;
    _shadowAnimation = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _shadowAnim = new Tween(begin: 0, end: 1).animate(_shadowAnimation);
    _listController.addListener(() {
      if (_listController.offset > MENU_SHADOW_THRESHOLD) {
        if (!shadowForward) {
          _shadowAnimation.forward();
          shadowForward = true;
        }
      } else {
        if (shadowForward) {
          _shadowAnimation.reverse();
          shadowForward = false;
        }
      }
    });
  }

  _shadowAnimate() {
    return AnimatedBuilder(
      animation: _shadowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
              color: (widget.onlyMenu)
                  ? Color.alphaBlend(
                      Colors.blue
                          .withOpacity(0.8 + (_shadowAnimation.value * 0.2)),
                      Colors.white)
                  : Color.alphaBlend(
                      Colors.black.withOpacity(_shadowAnimation.value * 0.2),
                      ThemeConstants.BGCOLOR_DARK),
              boxShadow: [
                BoxShadow(
                    blurRadius: _shadowAnimation.value * 12,
                    color: Colors.black54)
              ]),
          height: _menuHeight,
          width: double.infinity,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.BGCOLOR_DARK,
      body: Stack(
        children: (<Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: _menuHeight,
              ),
              Expanded(
                child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: widget.builder(context, _listController)),
              )
            ],
          )
        ]..addAll(_menuStack())),
      ),
    );
  }

  _menuStack() {
    return <Widget>[
      _shadowAnimate(),
      if (widget.roomCallback != null) _roomsMenu(),
      if (widget.searchCallback != null) _searchBar(),
//barrier

      ValueListenableBuilder(
        builder: (context, value, child) => (value)?Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ):SizedBox.shrink(),
        valueListenable: isShown,
      ),
      if (widget.onlyMenu)
        Positioned(
            top: _menuHeight - 40,
            left: 0,
            right: 0,
            child: SizedBox(
                width: double.infinity,
                child: Text(
                    widget.menuTitle ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ))),
      _menu(),
      _topMenuSheet(),
    ];
  }

  _menu() {
    return Positioned(
      top: (widget.onlyMenu) ? _menuHeight - 55 : _menuHeight - 68,
      right: 20,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: (widget.onlyMenu)
            ? Colors.transparent
            : ThemeConstants.BGCOLOR_DARK_COMP,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: EdgeInsets.only(left: 9, right: 9, top: 10, bottom: 10),
              child: Icon(
                Icons.menu,
                size: 30,
              )),
          onTap: () {
            isShown.value = !isShown.value;
            if (widget.menuCallback != null) widget.menuCallback(isShown.value);
          },
        ),
      ),
    );
  }

  ValueNotifier<String> selectedMenuItem = ValueNotifier("Chat Rooms");
  _topMenuSheet() {
    return ValueListenableBuilder(
        valueListenable: isShown,
        builder: (context, value, child) {
          return AnimatedPositioned(
            curve: Curves.easeInOutExpo,
            duration: Duration(milliseconds: 500),
            left: 0,
            right: 0,
            top: value ? -70 : -320,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shadowColor: Color(0xFF0088FF).withOpacity(0.6),
                elevation: 20,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                          bottom: 0,
                          child: AnimatedOpacity(
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              opacity: value ? 0.8 : 0,
                              child: WebsafeSvg.asset("svg/bg_purple.svg",
                                  width:
                                      MediaQuery.of(context).size.width - 20))),
                      Positioned(
                          bottom: -9,
                          right: -8,
                          child: AnimatedOpacity(
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              opacity: value ? 0.8 : 0,
                              child: Card(
                                  color: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(60)),
                                  child: IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      isShown.value = !value;
                                    },
                                  )))),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 200),
                          opacity: value ? 1 : 0,
                          child: Column(
                            children: [
                              SizedBox(height: 100),
                              ValueListenableBuilder(
                                  valueListenable: selectedMenuItem,
                                  builder: (context, value, child) {
                                    return Wrap(
                                      alignment: WrapAlignment.start,
                                      direction: Axis.horizontal,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            selectedMenuItem.value = "Papers";

                                            isShown.value = !isShown.value;
                                            if (widget.menuCallback != null)
                                              widget.menuCallback(
                                                  selectedMenuItem.value);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconTextOption(
                                              option: IconText(
                                                  selected: value == "Papers",
                                                  iconColor: Colors.blue,
                                                  icon: Icons.folder_shared,
                                                  text: "Papers    "),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            selectedMenuItem.value =
                                                "Chat Rooms";

                                            isShown.value = !isShown.value;
                                            if (widget.menuCallback != null)
                                              widget.menuCallback(
                                                  selectedMenuItem.value);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconTextOption(
                                              option: IconText(
                                                  selected:
                                                      value == "Chat Rooms",
                                                  iconColor: Colors.deepPurple,
                                                  icon:
                                                      Icons.chat_bubble_outline,
                                                  text: "Chat Rooms"),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            selectedMenuItem.value = "Feed";

                                            isShown.value = !isShown.value;
                                            if (widget.menuCallback != null)
                                              widget.menuCallback(
                                                  selectedMenuItem.value);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconTextOption(
                                              option: IconText(
                                                  selected: value == "Feed",
                                                  iconColor: Colors.red,
                                                  textColor: Colors.black,
                                                  icon: Icons.rss_feed,
                                                  text: "Feed        "),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            selectedMenuItem.value = "Services";
                                            isShown.value = !isShown.value;
                                            if (widget.menuCallback != null)
                                              widget.menuCallback(
                                                  selectedMenuItem.value);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconTextOption(
                                              option: IconText(
                                                  selected: value == "Services",
                                                  iconColor: Colors.teal,
                                                  icon: Icons.room_service,
                                                  text: "Services  "),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            selectedMenuItem.value = "Logout";
                                            isShown.value = !isShown.value;
                                            if(widget.menuCallback!=null) widget.menuCallback("logout");
                                            await AuthService()
                                                .logoutCurrentUser();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconTextOption(
                                              option: IconText(
                                                  textColor: Colors.black,
                                                  selected: value == "Logout",
                                                  iconColor: Colors.red,
                                                  icon: Icons.arrow_back,
                                                  text: "Sign Out "),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            height: 75,
                                            width: 1,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  ValueNotifier rooms = ValueNotifier(false);
  ValueNotifier currentRoomTag = ValueNotifier("Rooms");
  _roomsMenu() {
    return Positioned(
        child: Stack(
          children: [
            ValueListenableBuilder(
                valueListenable: isSearchClicked,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: value ? 0 : 1,
                    child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          rooms.value = true;
                          if (widget.roomCallback != null)
                            widget.roomCallback(rooms.value);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: currentRoomTag,
                              builder: (ctx, value, child) => Text("$value",
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800)),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 40,
                                color: ThemeConstants.ACCENT,
                              ),
                            )
                          ],
                        )),
                  );
                }),
            ValueListenableBuilder(
              valueListenable: rooms,
              builder: (context, value, child) {
                return AnimatedContainer(
                  height: value ? 160 : 0,
                  duration: Duration(milliseconds: 150),
                  child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              FlatButton(
                                onPressed: () {
                                  rooms.value = false;
                                  if (widget.roomCallback != null)
                                    widget.roomCallback(rooms.value,
                                        value: "ROOMS");
                                  currentRoomTag.value = "Rooms";
                                },
                                child: Text(
                                  "Rooms",
                                  style: ThemeConstants.ROOMS_MENU_TEXT_STYLE,
                                ),
                              ),
                              SizedBox(height: 10),
                              FlatButton(
                                onPressed: () {
                                  rooms.value = false;
                                  if (widget.roomCallback != null)
                                    widget.roomCallback(rooms.value,
                                        value: "CLUBS");

                                  currentRoomTag.value = "Clubs";
                                },
                                child: Text(
                                  "Clubs",
                                  style: ThemeConstants.ROOMS_MENU_TEXT_STYLE,
                                ),
                              )
                            ],
                          ),
                        ),
                      )),
                );
              },
            ),
          ],
        ),
        top: _menuHeight - 65,
        left: 20);
  }

  _searchBar() {
    double right = 85;
    return ValueListenableBuilder(
        valueListenable: isSearchClicked,
        builder: (context, value, child) {
          return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: value ? _menuHeight - 85 : _menuHeight - 65,
              right: right,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: (value)
                    ? MediaQuery.of(context).size.width - 20 - right
                    : 50,
                height: (value) ? 70 : 50,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: value ? 12 : 0,
                          color: Colors.black.withOpacity(0.15))
                    ],
                    borderRadius: BorderRadius.circular(12),
                    color: (value)
                        ? Color.alphaBlend(Colors.black.withOpacity(0.1),
                            ThemeConstants.BGCOLOR_DARK_COMP)
                        : ThemeConstants.BGCOLOR_DARK_COMP),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value)
                          Flexible(
                            flex: 0,
                            fit: FlexFit.loose,
                            child: SizedBox(
                              width: 20,
                            ),
                          ),
                        if (value)
                          Flexible(
                              flex: 1, fit: FlexFit.tight, child: TextField()),
                        Flexible(
                          flex: 0,
                          fit: FlexFit.loose,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              (value) ? Icons.close : Icons.search,
                              color: ThemeConstants.ACCENT,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      rooms.value = false; //close rooms
                      isSearchClicked.value = !value;
                      if (widget.searchCallback != null)
                        widget.searchCallback(isSearchClicked.value);
                    },
                  ),
                ),
              ));
        });
  }
}
