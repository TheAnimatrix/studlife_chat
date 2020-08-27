import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:studlife_chat/chat/bloc_model/chat.dart';

class ChatBloc extends Bloc<ChatEvent,ChatState>
{
  ChatBloc() : super(ChatState([],true));

  @override
  Stream<ChatState> mapEventToState(ChatEvent event) async *{
    final currentState = state;
    print("event ${event.runtimeType}");
    if(event is ClearAll)
    {
      yield ChatState([],true);
    }
    if(event is LoadOldMessages)
    {
      // List<Message> oldMessages = [];
      // for(int i=0;i<10;i++)
      // {
      //   oldMessages.add(Message(message: "yo wazzup", username: "Taher",time: DateTime.now()));
      // }
      yield ChatState.copyWithMore(oldState: currentState, newMessages: event.messages);
    }

    if(event is SendMessage)
    {
      yield ChatState.copyWith(oldState: currentState, newMessage: event.message);
    }


  }
  
}

class ChatState {
  final List<Message> receivedMessages;
  final List<Message> disappearingMessages;
  final bool initial;

  ChatState(this.receivedMessages,this.initial, {this.disappearingMessages});

  static ChatState copyWith({@required ChatState oldState, @required Message newMessage})
  {
    return ChatState(oldState.receivedMessages..add(newMessage),false);
  }

  
  static ChatState copyWithMore({@required ChatState oldState, @required List<Message> newMessages,bool append=false})
  {
    return ChatState((append?(oldState.receivedMessages..addAll(newMessages)):newMessages),false);
  }
}


class ChatEvent {
}

class LoadOldMessages extends ChatEvent {
  final List<Message> messages;

  LoadOldMessages(this.messages);
}

class ClearAll extends ChatEvent{}

class SendMessage extends ChatEvent {
  final Message message;
  SendMessage(this.message);
}