import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_2.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';
import 'package:studlife_chat/auth/changeNotifiers/AuthService.dart';
import 'package:studlife_chat/chat/bloc/chat.dart';
import 'package:studlife_chat/chat/bloc_model/chat.dart';
import 'package:studlife_chat/constants/themes.dart';
import 'package:studlife_chat/menu/screens/menu_demo.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatRoom extends StatefulWidget {
  ChatRoom({Key key}) : super(key: key);
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  double WIDTH;
  String TITLE;
  String TAG;
  TextEditingController _controller = TextEditingController();
  IO.Socket socket;
  String myUsername;
  Color myNameColor;
  @override
  void dispose() {
    socket?.clearListeners();
    socket?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    myNameColor = RandomColor().randomMaterialColor(
        colorSaturation: ColorSaturation.mediumSaturation,
        colorHue: ColorHue.multiple(colorHues: [
          ColorHue.blue,
          ColorHue.orange,
          ColorHue.pink,
          ColorHue.red,
          ColorHue.yellow
        ]));
    myUsername = AuthService.currentUsername;
    if (myUsername == null) {
      print("fallback username to email");
      AuthService().getUserEmail.then((value) {
        myUsername = value;
      });
    }
    BlocProvider.of<ChatBloc>(context).add(ClearAll());
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      socket = IO.io('http://183.83.48.186/chat', <String, dynamic>{
        'transports': ['websocket'],
        'extraHeaders': {'auth': 'bffr'} // optional
      });
      socket.on('connect_timeout', (_) {
        print("timed out");
      });
      socket.on('disconnect', (_) {
        print("disconnect");
      });
      socket.on('connect_error', (_) {
        print("error connecting");
      });
      socket.on('reconnecting', (_) {
        print("reconnecting");
      });
      socket.on('error', (e) {
        print("error $e");
        socket.connect();
      });
      socket.on('connect', (_) {
        print("connected");
        socket.emit('join', {"username": myUsername, "room": TITLE});
      });
      socket.on('OldMessages', (data) {
        print("OldMessages recovered ${data.length}");
        List<Message> oldMessages =
            (data as List).map((msg) => Message.fromJson(msg)).toList();
        BlocProvider.of<ChatBloc>(context).add(LoadOldMessages(oldMessages));
      });

      // socket.on('roomData', (data) {
      //   print("roomdata $data");
      // });

      socket.on('receiveMessage', (data) {
        BlocProvider.of<ChatBloc>(context)
            .add(SendMessage(Message.fromJson(data)));
      });
    });
  }

  ValueNotifier<bool> showInteractMessage = ValueNotifier(false);
  ValueNotifier<bool> privateMode = ValueNotifier(false);
  ValueNotifier<bool> replyMode = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    if (WIDTH == null) WIDTH = MediaQuery.of(context).size.width * 0.8;
    if (TITLE == null) {
      Map<String, dynamic> arguements =
          ModalRoute.of(context).settings.arguments;
      if (arguements.containsKey("title")) {
        TITLE = arguements["title"];
        TAG = arguements["tag"];
      } else {
        TITLE = "#temp";
        TAG = TITLE;
      }

      print("TITLE is $TITLE");
    }
    return Hero(
      tag: TAG,
      child: MenuWidget(
        menuTitle: TITLE,
        onlyMenu: true,
        menuCallback: (reason) {
          if (reason == "logout") {
            Navigator.pop(context);
          }
        },
        builder: (ctx, _scrollController) {
          return Stack(
            children: [
              Positioned(
                bottom: 0,
                top: 0,
                right: 0,
                left: 0,
                child:
                    BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
                  if (state.initial) {
                    BlocProvider.of<ChatBloc>(context).add(LoadOldMessages([]));
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    reverse: true,
                    itemBuilder: (ctx, i) {
                      i = state.receivedMessages.length - i;
                      if (i >= state.receivedMessages.length)
                        return ValueListenableBuilder(
                            valueListenable: showInteractMessage,
                            builder: (ctx, value, child) => AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                height: (value) ? 200 : 100));
                      if (i == -1) return SizedBox(height: 20);
                      return Column(children: [
                        if (state.receivedMessages[i].time != null &&
                            (i - 1 < 0 ||
                                (i - 1 >= 0 &&
                                    state.receivedMessages[i - 1].time !=
                                        null &&
                                    state.receivedMessages[i - 1].time.day <
                                        state.receivedMessages[i].time.day)))
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: Text(
                                  DateFormat.MMMMEEEEd()
                                      .format(state.receivedMessages[i].time),
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ),
                          ),
                        _buildItem(ctx, i, state.receivedMessages[i],
                            state.receivedMessages)
                      ]);
                    },
                    itemCount: state.receivedMessages.length + 2,
                    controller: _scrollController,
                  );
                }),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 70, maxHeight: 200),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Card(
                        shape: RoundedRectangleBorder(),
                        margin: EdgeInsets.zero,
                        color:
                            ThemeConstants.BGCOLOR_DARK_COMP.withOpacity(0.7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: showInteractMessage,
                              builder: (ctx, value, child) => AnimatedContainer(
                                height: (value) ? 95 : 0,
                                duration: Duration(milliseconds: 200),
                                color: ThemeConstants.BGCOLOR_DARK_COMP
                                    .withOpacity(0.3),
                                child: AnimatedOpacity(
                                  duration: Duration(milliseconds: 200),
                                  opacity: (value) ? 1 : 0,
                                  child: Column(
                                    children: [
                                      Align(
                                          alignment: Alignment.bottomRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: RichText(
                                                text: TextSpan(children: [
                                              TextSpan(
                                                  text: "Interacting with : ",
                                                  style: TextStyle(
                                                      color: Colors.white54,
                                                      fontFamily: 'PS')),
                                              TextSpan(
                                                  text:
                                                      "${(selected.value == -1) ? "Interact" : BlocProvider.of<ChatBloc>(context).state.receivedMessages[selected.value].username}",
                                                  style: TextStyle(
                                                      color: selected.value ==
                                                              -1
                                                          ? Colors.blueAccent
                                                          : BlocProvider.of<
                                                                          ChatBloc>(
                                                                      context)
                                                                  .state
                                                                  .receivedMessages[
                                                                      selected
                                                                          .value]
                                                                  .nameColor ??
                                                              Colors.blueAccent,
                                                      fontWeight:
                                                          FontWeight.bold))
                                            ])),
                                          )),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          SizedBox(width: 20),
                                          Card(
                                            color: ThemeConstants.BGCOLOR_DARK,
                                            margin: EdgeInsets.only(
                                                top: 10, bottom: 10, right: 5),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: InkWell(
                                              onTap: () {},
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      "DM",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Icon(Icons.add_box,
                                                        color: Colors.white70),
                                                    SizedBox(width: 5),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          ValueListenableBuilder(
                                            valueListenable: privateMode,
                                            builder: (ctx, value, child) =>
                                                Card(
                                              color: value
                                                  ? Colors.cyanAccent
                                                  : ThemeConstants.BGCOLOR_DARK,
                                              margin: EdgeInsets.only(
                                                  top: 10,
                                                  bottom: 10,
                                                  right: 5),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: InkWell(
                                                onTap: () {
                                                  privateMode.value =
                                                      !privateMode.value;
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        "Private",
                                                        style: TextStyle(
                                                            color: value
                                                                ? Colors.black
                                                                : Colors.cyan),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(
                                                          Icons
                                                              .chat_bubble_outline,
                                                          color: value
                                                              ? Colors.black
                                                              : Colors.cyan),
                                                      SizedBox(width: 5),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          ValueListenableBuilder(
                                            valueListenable: replyMode,
                                            builder: (ctx, value, child) =>
                                                Card(
                                              color: replyMode.value
                                                  ? Colors.orange
                                                  : ThemeConstants.BGCOLOR_DARK,
                                              margin: EdgeInsets.only(
                                                  top: 10,
                                                  bottom: 10,
                                                  right: 5),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: InkWell(
                                                onTap: () {
                                                  replyMode.value =
                                                      !replyMode.value;
                                                  if (BlocProvider.of<ChatBloc>(
                                                              context)
                                                          .state
                                                          .receivedMessages[
                                                              selected.value]
                                                          .isPrivate !=
                                                      null)
                                                    privateMode.value = true;
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        "Reply",
                                                        style: TextStyle(
                                                            color: replyMode
                                                                    .value
                                                                ? Colors.black
                                                                    .withOpacity(
                                                                        0.7)
                                                                : Colors
                                                                    .white70),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(Icons.reply,
                                                          color: replyMode.value
                                                              ? Colors.black
                                                                  .withOpacity(
                                                                      0.7)
                                                              : Colors.white70),
                                                      SizedBox(width: 5),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close),
                                            onPressed: () {
                                              showInteractMessage.value = false;
                                              selected.value = -1;
                                              privateMode.value = false;
                                              replyMode.value = false;
                                            },
                                          ),
                                          SizedBox(width: 20)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextField(
                                    maxLines: 6,
                                    minLines: 1,
                                    autocorrect: true,
                                    textInputAction: TextInputAction.send,
                                    controller: _controller,
                                    inputFormatters: [CustomInputFormatter()],
                                    onSubmitted: (t) {
                                      _submit(t, _scrollController);
                                    },
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Type your message here.."),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                IconButton(
                                    icon: Icon(Icons.send),
                                    onPressed: () {
                                      _submit(
                                          _controller.text, _scrollController);
                                    }),
                                SizedBox(
                                  width: 20,
                                ),
                              ],
                            ),
                            ValueListenableBuilder(
                              valueListenable: showInteractMessage,
                              builder: (ctx, value, child) => AnimatedContainer(
                                height: value ? 10 : 0,
                                duration: Duration(milliseconds: 200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  _submit(t, _scrollController) {
    if (t.trim().isEmpty) return;
    print("submitted ${_scrollController.position.maxScrollExtent}");
    Message message = Message(
      time: DateTime.now(),
      message: t.trimRight(),
      username: myUsername,
      nameColor: myNameColor,
      isPrivate: (selected.value == -1)
          ? null
          : (!privateMode.value)
              ? null
              : BlocProvider.of<ChatBloc>(context)
                  .state
                  .receivedMessages[selected.value]
                  .username,
      reply: (selected.value == -1)
          ? null
          : (!replyMode.value)?null:BlocProvider.of<ChatBloc>(context)
                  .state
                  .receivedMessages[selected.value]
    );
    // if (privateMode.value && selected.value!=-1)
    //   socket.emit('privateMessage',
    //       {"to_username":BlocProvider.of<ChatBloc>(context).state.receivedMessages[selected.value].username,"username": myUsername, "message": jsonEncode(message)});
    // else
    socket.emit('sendMessage',
        {"username": myUsername, "message": jsonEncode(message)});
    BlocProvider.of<ChatBloc>(context).add(SendMessage(message));
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut);
    _controller.clear();
  }

  _buildItem(ctx, i, Message message, List<Message> messages) {
    if (message.received == false || message.username == myUsername)
      return _buildRight(ctx, i, message, messages);
    else
      return _buildLeft(ctx, i, message, messages);
  }

  _buildRight(ctx, i, Message message, List<Message> messages) {
    return Column(
      children: [
        Align(
          key: UniqueKey(),
          alignment: Alignment.topRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: WIDTH),
            child: Padding(
              padding: EdgeInsets.only(right: 5, top: 4),
              child: ChatBubble(
                clipper:
                    ChatBubbleClipper4(type: BubbleType.sendBubble, nipSize: 5),
                backGroundColor: (message.isPrivate != null)
                    ? ThemeConstants.BGCOLOR_DARK_COMP
                    : ThemeConstants.RIGHT_CHAT_BUBBLE,
                alignment: Alignment.bottomRight,
                shadowColor: Colors.black26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    //create reply box if reply exists along with 10 padding on bottom
                    if (message.reply != null) _buildRight2(message.reply),
                    if (message.reply != null)
                      SizedBox(
                        height: 5,
                      ),
                    //show destination username if message is private
                    if (message.isPrivate != null)
                      Text("@${message.isPrivate}",
                          style: TextStyle(
                              backgroundColor: ThemeConstants.BGCOLOR_DARK_COMP,
                              color: Colors.blueAccent)),
                    //message itself
                    Text(message.message, style: TextStyle(fontSize: 15)),
                    //time
                    if (message.time != null)
                      Text(DateFormat.jm().format(message.time),
                          style:
                              TextStyle(color: Colors.white24, fontSize: 11)),
                    //private label
                    if (message.isPrivate != null)
                      Text("Private",
                          style:
                              TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _buildRight2(Message message,{bool left=false}) {
    return Card(
      color: Colors.black26,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isPrivate != null)
              Text("Private message", style: TextStyle(color: Colors.white54)),
            Text((message.username!=null)?(message.username==myUsername)?"You":message.username:"null",
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: message.nameColor)),
            Text(message.message ?? "null",
                textAlign: TextAlign.left, style: TextStyle(fontSize: 15)),
            if (message.time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10, bottom: 4),
                child: Text(DateFormat.jm().format(message.time),
                    style: TextStyle(color: Colors.white24, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  ValueNotifier<int> selected = ValueNotifier(-1);
  _buildLeft(ctx, i, Message message, List<Message> messages) {
    if (message.isPrivate != null && message.isPrivate != myUsername)
      return SizedBox.shrink();
    return Align(
        key: UniqueKey(),
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder(
          valueListenable: selected,
          builder: (ctx, value, child) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              color: (value == i) ? Colors.blueAccent : Colors.transparent,
              child: child,
            );
          },
          child: _buildLeftColumn(ctx, i, message, messages),
        ));
  }

  _buildLeftColumn(ctx, i, Message message, List<Message> messages) {
    return Column(children: [
      Align(
        alignment: Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: WIDTH),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Card(
              color: (message.isPrivate != null)
                  ? ThemeConstants.LEFT_CHAT_BUBBLE_PRIVATE
                  : ThemeConstants.BGCOLOR_DARK_COMP,
              child: InkWell(
                onLongPress: () {
                  if (selected.value == i) {
                    selected.value = -1;
                    showInteractMessage.value = false;
                  } else {
                    selected.value = i;
                    showInteractMessage.value = false;
                    showInteractMessage.value = true;
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 6, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(message.reply!=null)Transform.translate(offset: Offset(-4,0),child:_buildRight2(message.reply,left:true)),
                      if(message.reply!=null)SizedBox(height: 5),
                      if (message.isPrivate != null)
                        Text("Private message",
                            style: TextStyle(color: Colors.white54)),
                      Text(message.username ?? "null",
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: message.nameColor)),
                      Text(message.message ?? "null",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 15)),
                      if (message.time != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 2, right: 10, bottom: 4),
                          child: Text(DateFormat.jm().format(message.time),
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class CustomInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
        text: newValue.text.trimLeft(),
        selection: newValue.selection,
        composing: newValue.composing);
  }
}
