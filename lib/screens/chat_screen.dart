import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';
import '../widgets/profile_image.dart';
import 'view_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  //for storing all messages
  List<Message> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();

  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),
        backgroundColor: const Color.fromARGB(255, 234, 248, 255),
        body: SafeArea(child: Column(
          children: [

            Expanded(
              child: StreamBuilder(
                // Real-time stream of all users from Firebase
                // stream: APIs.getAllUsers(),

                builder: (context, snapshot) {
                  // Handle different connection states
                  switch (snapshot.connectionState) {
                  // Show loading indicator while waiting for data
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      // return const Center(child: CircularProgressIndicator());

                  // Data is being streamed or stream completed
                    case ConnectionState.active:
                    case ConnectionState.done:
                    // Extract documents from snapshot
                    //   final data = snapshot.data?.docs;
                    //
                    //   // Convert Firebase documents to ChatUser objects
                    //   _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

                      // Check if user list is not empty
                      if (_list.isNotEmpty) {
                        // ========== DISPLAY LIST OF USERS ==========
                        return ListView.builder(
                          // Show search results count if searching, otherwise show all users
                          itemCount:_list.length,

                          // Add padding at top of list
                          padding: EdgeInsets.only(top: mq.height * 0.01),

                          // Bouncing scroll effect (iOS style)
                          physics: BouncingScrollPhysics(),

                          // Build each user card
                          itemBuilder: (context, index) {
                            return Text("Message");
                          },
                        );
                      } else {
                        // ========== EMPTY STATE ==========
                        // Show message when no msg are found
                        return const Center(
                          child: Text(
                            'Say Hii! 👋',
                            style: TextStyle(fontSize: 20),
                          ),
                        );
                      }
                  }
                }, stream: null,
              ),
            ),

            _chatInput()
          ],

        )),
      ),
    );
  }

  Widget _appBar(){
    return InkWell(
      onTap: (){},
      child: Row(
        children: [
      
          //back button
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back,
                  color: Colors.black54)),
          // profile pic
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * 0.03),
            child: CachedNetworkImage(
              width: mq.height * 0.05,
              height: mq.height * 0.05,
              fit: BoxFit.cover,
              imageUrl: widget.user.image,
              placeholder:(context,url)=>CircularProgressIndicator(),
              errorWidget:(context,url,error)=>CircleAvatar(child: Icon(Icons.person)),
            ),
          ),
      
          SizedBox(width: 10,),
      
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),),
              //for adding some space
              const SizedBox(height: 2),
      
              //last seen time of user
              Text("Last seen", style: const TextStyle(
                  fontSize: 13, color: Colors.black54),),
      
      
            ],
          ),
      
      
      
        ],
      ),
    );
  }

  Widget _chatInput(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Row(
                children: [
                  //emoji btn
                  IconButton(onPressed: (){}, icon: const Icon(Icons.emoji_emotions,color: Colors.blueAccent,)),
                 // text field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                      },
                      decoration: const InputDecoration(
                          hintText: 'Type Something...',
                          hintStyle: TextStyle(color: Colors.blueAccent),
                          border: InputBorder.none),
                    ),
                  ),

                  //pic
                  IconButton(onPressed: (){}, icon: const Icon(Icons.image,color: Colors.blueAccent,)),
                  //camera
                  IconButton(onPressed: (){}, icon: const Icon(Icons.camera_alt_outlined,color: Colors.blueAccent,)),
                  //adding some space
                  SizedBox(width: mq.width * .01),

                ],
              ),
            ),
          ),
          //send message button
          MaterialButton(
            onPressed: () {

            },
            minWidth: 0,
            padding:
            const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: Colors.lightBlue,
            child: const Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }
}
