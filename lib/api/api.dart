import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import '../models/chat_user.dart';
import '../models/message.dart' as msg_model;
import 'notification_access_token.dart';
import "package:chat_app/services/cloudinary_service.dart"; // adjust path


class APIs{
  //authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for storing self information


  //firestore
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static get user=>auth.currentUser!;

  static ChatUser me = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using Orbit!",
      image: user.photoURL.toString(),
      createdAt: '',
      isOnline: false,
      lastActive: '',
      pushToken: '');

//check if user exist?
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        // await getFirebaseMessagingToken();
        //
        // //for setting user status to active
        // APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }


//to create a new user

  static Future<void> createUser()async{
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using Orbit!",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '');

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }
  static Future<void> updateUserInfo() async {
    try {
      log("Updating user...");
      log("UID: ${user.uid}");
      log("Name: ${me.name}");
      log("About: ${me.about}");

      await firestore.collection('users').doc(user.uid).update({
        "name": me.name,
        "about": me.about,
      });

      log("✅ FIRESTORE UPDATED SUCCESSFULLY");
    } catch (e) {
      log("❌ ERROR: $e");
    }
  }

  // user profile image using cloudinary
  static Future<bool> updateProfileImage(File imageFile) async {
    if (auth.currentUser == null) {
      log('❌ updateProfileImage: no authenticated user');
      return false;
    }

    // This matches your CloudinaryService.uploadImage(File imageFile) definition
    final imageUrl = await CloudinaryService.uploadImage(imageFile);

    if (imageUrl == null || imageUrl.isEmpty) {
      log('❌ updateProfileImage: upload failed');
      return false;
    }

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'image': imageUrl});

      me.image = imageUrl;
      log('✅ Profile image saved for ${user.uid}');
      return true;
    } catch (e) {
      log('❌ Firestore Update Error: $e');
      return false;
    }
  }

  ///********************** chat screen related apis **********************************
  ///  chats(coll) -> conv_id(doc) -> msg(coll)->msg(doc)

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // to get all msg for a specific convo from firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/').snapshots();
  }


  static Future<void> sendMessage(ChatUser chatUser, String msg) async{

    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final msg_model.Message message = msg_model.Message(
        toId: chatUser.id,
        msg: msg,
        read: '',
        type: msg_model.Type.text,
        fromId: user.uid,
        sent: time);
    final ref= firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());

  }

  //update read status of message
  static Future<void> updateMessageReadStatus(msg_model.Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/').doc(message.sent).update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true).limit(1).snapshots();
  }

}