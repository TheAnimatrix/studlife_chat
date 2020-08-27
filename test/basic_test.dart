

import 'package:studlife_chat/bloc_models/rooms.dart';

void main(){

  List<dynamic> arr = ["a","b","c"];

  List<Room> rooms = arr.map((e)=>new Room(name: e)).toList();

  print(rooms.toString());

}