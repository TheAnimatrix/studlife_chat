import 'package:studlife_chat/bloc_models/blocmodel.dart';

class Room extends BlocModel {
  final String name;
  final String tag;
  final int onlineUsers;
  final String id;
  bool favorite = false;
  
  Room({this.favorite=false,this.id,this.name,this.tag, this.onlineUsers, });

  Room.fromJson(Map<String, dynamic> json) : name = json['roomName'],tag = json['tag'],onlineUsers=json['onlineUsers'],id=json['_id'], super.fromJson(null);

  Map<String,dynamic> toJson() => {
    'Name':name,
    '_id':id
  };

  @override
  String toString() {
    return name;
  }
}
