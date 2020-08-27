import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:studlife_chat/bloc_http/rooms.dart';
import 'package:studlife_chat/bloc_models/rooms.dart';

class RoomsBloc extends Bloc<RoomEvent, RoomState> {
  final RoomsHttp roomsHttp;
  RoomsBloc({@required this.roomsHttp}) : super(InitialState());

  @override
  Stream<RoomState> mapEventToState(RoomEvent event) async* {
    final currentState = state;
    if (event is ForceReloadOfficialRooms && event.indicator) {
      yield InitialState();
      return;
    }
    if ((event is FetchOfficialRooms && currentState is InitialState) ||
        event is ForceReloadOfficialRooms) {
      List<Room> officialRooms;
      List<Room> pinnedRooms = [];
      if (currentState is AllRoomsState)
        pinnedRooms = currentState.officialPinned;
      try {
        officialRooms = await roomsHttp.getOfficialRooms();
      } catch (e) {
        yield ErrorState();
        return;
      }
      pinnedRooms = pinnedRooms.map((e){
        for (int i = 0; i < officialRooms.length; i++) {
          if (e.id == officialRooms[i].id) {
            { return officialRooms.removeAt(i)..favorite=true;}
          }
        }
        return e;
      }).toList();
      
      officialRooms.insertAll(0, pinnedRooms);
      yield AllRoomsState(
          officialRooms: officialRooms,
          secondaryRooms: [],
          officialPinned: pinnedRooms);
    }
    if (event is FavoriteRoom && currentState is AllRoomsState) {
      List<Room> officialRooms;
      List<Room> pinnedRooms = currentState.officialPinned ?? [];
      bool add = true;
      {//if room exists, remove it else add it..
        for (int i = 0; i < pinnedRooms.length; i++)
          if (pinnedRooms[i].id == event.room.id) {
            pinnedRooms.removeAt(i);
            add = false;
            break;
          }

        if (add)
          pinnedRooms
            ..add(event.room..favorite = true)
            ..sort((room1, room2) {
              return room1.name.compareTo(room2.name);
            });
      }

      //http get rooms
      try {
        officialRooms = await roomsHttp.getOfficialRooms();
      } catch (e) {
        yield ErrorState();
        return;
      }
      //remove favorites for http list
      for (Room favorite in pinnedRooms) {
        for (int i = 0; i < officialRooms.length; i++) {
          if (favorite.id == officialRooms[i].id) {
            officialRooms.removeAt(i);
            continue;
          }
        }
      }
      //add them to start
      officialRooms.insertAll(0, pinnedRooms);

      print("$officialRooms OFFC $pinnedRooms pinned");
      //publish state
      yield AllRoomsState(
          officialRooms: officialRooms,
          secondaryRooms: [],
          officialPinned: pinnedRooms);
    }
  }
}

class RoomState {}

class InitialState extends RoomState {}

class ErrorState extends RoomState {}

class AllRoomsState extends RoomState {
  final List<Room> officialRooms;
  List<Room> officialPinned;
  final List<Room> secondaryRooms;

  AllRoomsState(
      {this.officialRooms, this.secondaryRooms, List<Room> officialPinned}) {
    this.officialPinned = officialPinned ?? this.officialPinned ?? [];
  }
}

class RoomEvent {}

class ForceReloadOfficialRooms extends RoomEvent {
  final bool indicator;

  ForceReloadOfficialRooms({this.indicator = false});
}

class FavoriteRoom extends RoomEvent {
  final Room room;

  FavoriteRoom(this.room);
}

class FetchOfficialRooms extends RoomEvent {}
