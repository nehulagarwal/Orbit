import 'dart:developer';

import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    // ── App lifecycle: update online status ───────────────────────────────
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume'))
          APIs.updateActiveStatus(true);
        if (message.toString().contains('pause'))
          APIs.updateActiveStatus(false);
      }
      return Future.value(message);
    });

    // ── Foreground notifications ──────────────────────────────────────────
    // When the app is open and a message arrives, show a snackbar with
    // the sender's name and tap-to-open behaviour.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📬 Foreground notification: ${message.notification?.title}');
      final notification = message.notification;
      if (notification == null) return;

      // Only show if we have a mounted context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue.withOpacity(0.9),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.message, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      notification.body ?? '',
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tap the snackbar → open the chat if sender is in our list
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openChatFromNotification(message.data),
          ),
        ),
      );
    });

    // ── Notification tap while app is in background (not terminated) ──────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📱 Notification tapped (background): ${message.data}');
      _openChatFromNotification(message.data);
    });

    // ── Notification tap that launched the app from terminated state ──────
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        log('🚀 App opened from terminated via notification');
        // Small delay so the widget tree is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _openChatFromNotification(message.data);
        });
      }
    });
  }

  /// Finds the matching [ChatUser] from our list and pushes [ChatScreen].
  void _openChatFromNotification(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String?;
    if (senderId == null || senderId.isEmpty) return;

    // Try to find sender in the already-loaded list
    final matches = _list.where((u) => u.id == senderId).toList();
    if (matches.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(user: matches.first)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() => _isSearching = false);
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email, ...',
              ),
              autofocus: true,
              style: const TextStyle(fontSize: 16, letterSpacing: 0.7),
              onChanged: (val) {
                _searchList.clear();
                for (var u in _list) {
                  if (u.name.toLowerCase().contains(val.toLowerCase()) ||
                      u.email.toLowerCase().contains(val.toLowerCase())) {
                    _searchList.add(u);
                  }
                }
                setState(() {});
              },
            )
                : const Text('Orbit'),
            leading: const Icon(Icons.home),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isSearching = !_isSearching),
                icon: Icon(_isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me)),
                ),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),

          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () async {
                await APIs.auth.signOut();
                await GoogleSignIn.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),

          body: StreamBuilder(
            stream: APIs.getAllUsers(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  _list = data
                      ?.map((e) => ChatUser.fromJson(e.data()))
                      .toList() ??
                      [];

                  if (_list.isNotEmpty) {
                    return ListView.builder(
                      itemCount:
                      _isSearching ? _searchList.length : _list.length,
                      padding: EdgeInsets.only(top: mq.height * 0.01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) => ChatUserCard(
                        user: _isSearching ? _searchList[index] : _list[index],
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text('No Connections Found!',
                          style: TextStyle(fontSize: 20)),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}