
import 'package:dio/dio.dart';
import 'package:studlife_chat/bloc_models/rooms.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RoomsHttp
{
  Dio dio;
  static const String URL = "http://183.83.48.186";
  static const GETOfficialRooms = "/user/rooms/official";
  RoomsHttp(){ dio = Dio()..options=BaseOptions(baseUrl: URL,connectTimeout: 10000); }

  Future<List<Room>> getOfficialRooms() async
  {
    Response result;
    try{
      result = await dio.get(GETOfficialRooms,options: Options(validateStatus: (_)=>true));
      //result is 200 guaranteed;
      List<Room> officialRooms = [];
      result.data["data"]["Rooms"].forEach((e)=>officialRooms.add(Room.fromJson(e)));
      return officialRooms;
    } on DioError catch(e)
    {
      throw {"error":"Failed to get official rooms","errorData":"$e ${result?.statusCode} ${result?.statusMessage} ${result?.toString()}"};
    }
  }

  dispose()
  {
    dio?.close();
  }

}