import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Message {
  String username;
  String message;
  DateTime time;
  bool received;
  Color nameColor;
  String isPrivate;
  Message reply;

  Message(
      {this.nameColor = Colors.blueAccent,
      this.username,
      this.message,
      this.time,
      this.received = false,
      this.isPrivate,this.reply});

  Message.fromJson(json,{doReply=true})
      : username = json['username'] ?? json['sent'] ?? "null" {
    final Map<String, dynamic> parsed = doReply?_getMapFromObject(json["message"]):json;
    if(!doReply) username = parsed["username"];
    message = _getMessageFromObject(parsed);
    time = _getDateTimeFromObject(parsed);
    nameColor = _getColorFromObject(parsed);
    isPrivate = _isPrivateFromObject(parsed);
    received = true;
    try{
    reply = (parsed["reply"]!=null)?_replyFromObject(parsed["reply"]):null;
    }catch(e)
    {
      print("error occurs here $e");
    }
    print("$isPrivate $message");
  }

  static _getMapFromObject(String json) {
    try {
      return jsonDecode(json);
    } catch (e) {
      return json;
    }
  }

  static _replyFromObject(dynamic data) {
      print("Data reply : $data");
      final reply = jsonDecode(data);
      return Message.fromJson(reply,doReply: false);
      // print("data check ${reply["message"]}");
      // final message = _getMessageFromObject(reply);
      // return Message(message: message);
  }


  static _getMessageFromObject(data) {
    try {
      return data["message"];
    } catch (e) {
      return "error, this message was corrupted";
    }
  }

  static String _isPrivateFromObject(data) {
    try {
      if (data["private"] is bool) return null;
      return data["private"] ?? null;
    } catch (e) {
      return null;
    }
  }

  static _getDateTimeFromObject(data) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(data["timestamp"]);
    } catch (e) {
      print("parse datetime error $e");
      return null;
    }
  }

  static _getColorFromObject(object) {
    try {
      return stringToColor(object["color"]);
    } catch (e) {
      return Colors.blueAccent;
    }
  }

  static Message copyWithoutReply(Message message) {
    return Message(
        username: message.username,
        isPrivate: message.isPrivate,
        message: message.message,
        nameColor: message.nameColor,
        received: message.received,
        time: message.time);
  }

  Map<String, dynamic> toJson() => {
        'username':username,
        'message': message,
        'color': colorToString(nameColor),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'private': isPrivate ?? false,
        'reply': (reply == null)
            ? null
            : (reply.reply == null)
                ? jsonEncode(reply)
                : jsonEncode(Message.copyWithoutReply(reply))
      };

  // Map<String, dynamic> toJson() => {
  //       'username': username,
  //       'message': encodeMessageString(),
  //       'timestamp': time.millisecondsSinceEpoch
  //     };

  @override
  String toString() {
    return "$username ${this.received ? 'received' : 'sent'} private:$isPrivate $message at ${time.toString()}";
  }

  static String colorToString(Color color) {
    return color.toString();
  }

  static Color stringToColor(String color) {
    String valueString = color.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    return Color(value);
  }
}
