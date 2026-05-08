import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';
import 'dialogs/profile_dialog.dart';
import 'profile_image.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0.55,
      child: InkWell(
        onTap: () {
          //for navigating to chat screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(stream: APIs.getLastMessage(widget.user), builder: (context,snapshot){

          final data=snapshot.data?.docs;
          final list =
              data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
          if (list.isNotEmpty) _message = list[0];

          return ListTile(
              title: Text(widget.user.name),

              subtitle:  Text( _message!= null ?  _message!.msg:
                widget.user.about,
                maxLines: 1,
              ),

              leading: ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.3),
                child: CachedNetworkImage(
                  width: mq.height * 0.055,
                  height: mq.height * 0.055,
                  imageUrl:
                  widget.user.image
                  ,
                  placeholder:(context,url)=>CircularProgressIndicator() ,
                  errorWidget:(context,url,error)=>CircleAvatar(child: Icon(Icons.person)) ,
                ),
              ),

              trailing: _message==null ? null :
              _message!.read.isEmpty && _message!.fromId != APIs.user.uid
                  ?
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.greenAccent,
                ),
              ) :
              Text(
                MyDateUtil.getLastMessageTime(
                    context: context, time: _message!.sent),
                style: const TextStyle(color: Colors.black54),
              ),
          );
        },)
        
      ),
    );
  }
}