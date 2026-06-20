import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/chat_user.dart';
import '../models/message.dart' as msg_model;
import 'notification_access_token.dart';
import 'package:chat_app/services/cloudinary_service.dart';

class APIs {
  // ── Auth & Firestore ───────────────────────────────────────────────────────
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static User get user => auth.currentUser!;

  static ChatUser me = ChatUser(
    id: user.uid,
    name: user.displayName.toString(),
    email: user.email.toString(),
    about: "Hey, I'm using Orbit!",
    image: user.photoURL.toString(),
    createdAt: '',
    isOnline: false,
    lastActive: '',
    pushToken: '',
  );

  // ── FCM token ──────────────────────────────────────────────────────────────
  static FirebaseMessaging fmessaging = FirebaseMessaging.instance;

  static Future<void> getFirebaseMessagingToken() async {
    await fmessaging.requestPermission();

    // FIX: await the token properly so updateActiveStatus saves it
    final t = await fmessaging.getToken();
    if (t != null) {
      me.pushToken = t;
      log('✅ FCM token: $t');
    }

    // Listen for token refresh
    fmessaging.onTokenRefresh.listen((newToken) {
      me.pushToken = newToken;
      // Save refreshed token to Firestore immediately
      firestore
          .collection('users')
          .doc(user.uid)
          .update({'push_token': newToken});
      log('🔄 FCM token refreshed: $newToken');
    });
  }

  // ── User info ──────────────────────────────────────────────────────────────
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((u) async {
      if (u.exists) {
        me = ChatUser.fromJson(u.data()!);
        await getFirebaseMessagingToken(); // await so token is ready
        APIs.updateActiveStatus(true);    // now push_token is non-empty
        log('My Data: ${u.data()}');
      } else {
        await createUser().then((_) => getSelfInfo());
      }
    });
  }

  static Future<void> createUser() async {
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
      pushToken: '',
    );
    return firestore.collection('users').doc(user.uid).set(chatUser.toJson());
  }

  static Future<bool> userExists() async =>
      (await firestore.collection('users').doc(user.uid).get()).exists;

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() =>
      firestore.collection('users').doc(user.uid).collection('my_users').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() =>
      firestore.collection('users').where('id', isNotEqualTo: user.uid).snapshots();

  static Future<void> updateUserInfo() async {
    try {
      await firestore.collection('users').doc(user.uid).update({
        'name': me.name,
        'about': me.about,
      });
      log('✅ User info updated');
    } catch (e) {
      log('❌ updateUserInfo: $e');
    }
  }

  static Future<bool> updateProfileImage(File imageFile) async {
    if (auth.currentUser == null) return false;
    final imageUrl = await CloudinaryService.uploadImage(imageFile);
    if (imageUrl == null || imageUrl.isEmpty) return false;
    try {
      await firestore.collection('users').doc(user.uid).update({'image': imageUrl});
      me.image = imageUrl;
      log('✅ Profile image saved');
      return true;
    } catch (e) {
      log('❌ updateProfileImage Firestore: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser chatUser) =>
      firestore.collection('users').where('id', isEqualTo: chatUser.id).snapshots();

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  // ── Conversation helpers ───────────────────────────────────────────────────
  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser u) =>
      firestore
          .collection('chats/${getConversationID(u.id)}/messages/')
          .orderBy('sent', descending: true)
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser u) =>
      firestore
          .collection('chats/${getConversationID(u.id)}/messages/')
          .orderBy('sent', descending: true)
          .limit(1)
          .snapshots();

  static Future<void> updateMessageReadStatus(msg_model.Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  // ── Send text message ──────────────────────────────────────────────────────
  static Future<void> sendMessage(ChatUser chatUser, String msg) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final message = msg_model.Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: msg_model.Type.text,
      fromId: user.uid,
      sent: time,
    );

    await firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/')
        .doc(time)
        .set(message.toJson());

    // Send push notification to recipient
    await sendPushNotification(
      chatUser: chatUser,
      msg: msg,
      msgType: 'text',
    );
  }

  // ── Send image message ─────────────────────────────────────────────────────
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final conversationId = getConversationID(chatUser.id);
    log('📸 Uploading chat image for conversation: $conversationId');

    final imageUrl = await CloudinaryService.uploadChatImage(
      imageFile: file,
      conversationId: conversationId,
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      log('❌ sendChatImage: Cloudinary upload failed');
      return;
    }

    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final message = msg_model.Message(
      toId: chatUser.id,
      msg: imageUrl,
      read: '',
      type: msg_model.Type.image,
      fromId: user.uid,
      sent: time,
    );

    await firestore
        .collection('chats/$conversationId/messages/')
        .doc(time)
        .set(message.toJson());

    log('✅ Chat image message saved to Firestore');

    // Send push notification to recipient
    await sendPushNotification(
      chatUser: chatUser,
      msg: 'Sent you a photo 📸',
      msgType: 'image',
    );
  }

  // ── Push notification via FCM HTTP v1 API ──────────────────────────────────
  static Future<void> sendPushNotification({
    required ChatUser chatUser,
    required String msg,
    required String msgType, // 'text' or 'image'
  }) async {
    // Don't send if recipient has no token
    if (chatUser.pushToken.isEmpty) {
      log('⚠️ No push token for ${chatUser.name}, skipping notification');
      return;
    }

    try {
      // 1. Get a fresh OAuth2 access token
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        log('❌ sendPushNotification: could not get access token');
        return;
      }

      // 2. Build the FCM v1 message payload
      final body = jsonEncode({
        'message': {
          'token': chatUser.pushToken,
          'notification': {
            'title': me.name,                    // sender's name as title
            'body': msgType == 'image' ? 'Sent you a photo 📸' : msg,
          },
          'data': {
            'senderId':   user.uid,
            'senderName': me.name,
            'msgType':    msgType,
          },
          'android': {
            'priority': 'high',
            'notification': {'sound': 'default'},
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
        },
      });

      // 3. POST to FCM HTTP v1
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/orbit-47bed/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log('✅ Notification sent to ${chatUser.name}');
      } else {
        log('❌ FCM error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('❌ sendPushNotification exception: $e');
    }
  }
}