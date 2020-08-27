import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studlife_chat/auth/changeNotifiers/AuthService.dart';
import 'package:studlife_chat/bloc/rooms.dart';
import 'package:studlife_chat/bloc_http/rooms.dart';
import 'package:studlife_chat/constants/themes.dart';

import 'menu_demo.dart';

class RoomsPage extends StatefulWidget {
  final bool askUsername;

  const RoomsPage({Key key, this.askUsername = false}) : super(key: key);

  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _showUsernameDialog();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (ctx) => RoomsHttp(),
      child: BlocProvider(
        create: (context) =>
            RoomsBloc(roomsHttp: RepositoryProvider.of<RoomsHttp>(context)),
        child: MenuWidget(
          builder: (ctx, _controller) {
            return _MenuBody(ctx, _controller);
          },
          menuCallback: (v) {
            print("menu called $v");
          },
          roomCallback: (v, {value}) {
            print("room called $v ${!v ? value : ""}");
          },
          searchCallback: (v) {
            print("search called $v");
          },
        ),
      ),
    );
  }

  @override
  dispose()
  {
    runOnce=false;
    t.cancel();
    t=null;
    super.dispose();
  }

  bool runOnce = true;
  Timer t;
  _MenuBody(ctx, _controller) {
    return BlocBuilder<RoomsBloc, RoomState>(builder: (context, state) {
      if (runOnce) {
        runOnce = false;
        if (t == null || !t.isActive)
          t = Timer.periodic(const Duration(seconds: 5), (t) {
            // print("force reload 5s");
            BlocProvider.of<RoomsBloc>(ctx).add(ForceReloadOfficialRooms());
          });
      }
      if (state is InitialState) {
        BlocProvider.of<RoomsBloc>(context).add(FetchOfficialRooms());
        return Center(child: CircularProgressIndicator());
      }
      if (state is ErrorState)
        return Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error occured, try again"),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                BlocProvider.of<RoomsBloc>(context)
                    .add(ForceReloadOfficialRooms(indicator: true));
              },
            )
          ],
        ));
      if (state is AllRoomsState)
        return ListView.builder(
          controller: _controller,
          itemBuilder: (ctx, i) {
            return Hero(
              tag: "heroRoom$i",
              child: Card(
                color: ThemeConstants.BGCOLOR_DARK_COMP,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.only(top: 5, left: 20, bottom: 8, right: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/chatroom', arguments: {
                      "title": state.officialRooms[i].name,
                      "tag": "heroRoom$i"
                    });
                  },
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.only(top: 10, left: 20, bottom: 8),
                    trailing: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: Icon(
                            Icons.star,
                            color: state.officialRooms[i].favorite
                                ? Colors.cyan
                                : Colors.white24,
                          ),
                          onPressed: () {
                            BlocProvider.of<RoomsBloc>(context)
                                .add(FavoriteRoom(state.officialRooms[i]));
                          },
                        )),
                    title: Text("${state.officialRooms[i].toString()}"),
                    subtitle: RichText(
                      text: TextSpan(
                          style: TextStyle(fontFamily: 'PS'),
                          children: [
                            TextSpan(
                                text: "#${state.officialRooms[i].tag}\n",
                                style: TextStyle(
                                    fontFamily: 'PS',
                                    color: ThemeConstants.TEXT_CHAT_TAG)),
                            TextSpan(
                                text:
                                    "${state.officialRooms[i].onlineUsers} online",
                                style: TextStyle(
                                    color: ThemeConstants.TEXT_CHAT_ACTIVE))
                          ]),
                    ),
                  ),
                ),
              ),
            );
          },
          itemCount: state.officialRooms.length,
        );
    });
  }

  _showUsernameDialog() {
    ValueNotifier<bool> showLoading = ValueNotifier(false);
    GlobalKey<FormState> _formKey = GlobalKey();
    TextEditingController _editingController = TextEditingController();
    String errorString = null;
    if (widget.askUsername)
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            builder: (ctx) {
              return WillPopScope(
                  key: ValueKey("usernameDialog"),
                  onWillPop: () async => false,
                  child: ValueListenableBuilder(
                      valueListenable: showLoading,
                      builder: (context, value, child) {
                        
                          return Stack(
                            children: [
                              Container(
                                  height: MediaQuery.of(context).size.height * 0.8,
                                  color: ThemeConstants.BGCOLOR_DARK,
                                  child: Center(
                                      child: Column(
                                    children: [
                                      SizedBox(height: 20),
                                                                            Text(
                                        "Enter your username",
                                        style:
                                            TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Choose your PERMANENT username carefully",
                                        style:
                                            TextStyle(fontWeight: FontWeight.bold,color: Colors.blueAccent),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Card(
                                          color: ThemeConstants.BGCOLOR_DARK_COMP,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Form(
                                              key: _formKey,
                                              child: TextFormField(
                                                controller: _editingController,
                                                validator: (text) {
                                                  if(errorString!=null) return errorString;
                                                  if (text.length <= 6)
                                                    return "Username must be longer that 6 letters";
                                                  if (text.length > 30)
                                                    return "Username must be less than 31 letters";
                                                },
                                                decoration: InputDecoration(
                                                    hintText: "your username here",
                                                    border: InputBorder.none),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                          alignment: Alignment.topRight,
                                          child: RawMaterialButton(
                                            onPressed: () async {
                                              
                                                errorString = null;
                                              if (_formKey.currentState
                                                  .validate()) {
                                                //http
                                                showLoading.value = true;
                                                dynamic response =
                                                    await AuthService.postUserName(
                                                        _editingController.text);
                                                if (response
                                                    is bool) if (response) {
                                                  //true->ok
                                                  showLoading.value = false;
                                                  Navigator.pop(context);
                                                } else {
                                                  //false->conflict
                                                  showLoading.value = false;
                                                  errorString = "Username is already taken";
                                                  _formKey.currentState.validate();
                                                }
                                                else {
                                                  //null
                                                  errorString = "Unknown error occured try again";
                                                  showLoading.value = false;
                                                  _formKey.currentState.validate();
                                                }
                                              }
                                            },
                                            shape: CircleBorder(),
                                            fillColor: Colors.blueAccent,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Icon(
                                                Icons.done,
                                              ),
                                            ),
                                          )),
                                      Text("or"),
                                      SizedBox(height: 10),
                                      Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FlatButton(
                                            child: Text("Use my e-mail"),
                                            color: ThemeConstants.BGCOLOR_DARK_COMP,
                                            onPressed: () async {
                                              showLoading.value = true;
                                              await AuthService.postUserName(
                                                  await AuthService().getUserEmail);
                                              showLoading.value = false;
                                              Navigator.pop(context);
                                            },
                                          ))
                                          
                                    ],
                                  ))),
                            if (value)
                           Container(
                              color: ThemeConstants.BGCOLOR_DARK.withOpacity(0.5),
                              height: double.infinity,
                              child:
                                  Center(child: CircularProgressIndicator())),],
                          );
                      }));
            }).then((data) {});
      });
  }
}
