import 'dart:developer';

import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api.dart';

/// HomeScreen - Main screen that displays list of chat users
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List to store all users fetched from Firebase
  List<ChatUser> _list = [];

  // List to store filtered/searched users
  final List<ChatUser> _searchList = [];

  // Boolean flag to toggle search mode on/off
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch current user's information from Firebase when screen loads
    APIs.getSelfInfo();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when user taps anywhere outside text field
      onTap: () => FocusScope.of(context).unfocus(),

      child: WillPopScope(
        // Handle back button press behavior
        onWillPop: () {
          // If search is active
          if (_isSearching) {
            setState(() {
              // Close search mode instead of popping the screen
              _isSearching = !_isSearching;
            });
            // Don't allow screen to pop
            return Future.value(false);
          } else {
            // Allow normal back button behavior (pop the screen)
            return Future.value(true);
          }
        },

        child: Scaffold(
          // ========== APP BAR ==========
          appBar: AppBar(
            // Conditionally show search field or app title
            title: _isSearching
                ? TextField(
              // Search input field styling
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email, ...',
              ),
              // Auto-focus when search mode is activated
              autofocus: true,
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 0.7,
              ),
              // Called every time user types in search field
              onChanged: (val) {
                // Clear previous search results
                _searchList.clear();

                // Loop through all users
                for (var i in _list) {
                  // Check if user's name or email contains search query (case-insensitive)
                  if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                      i.email.toLowerCase().contains(val.toLowerCase())) {
                    // Add matching user to search results
                    _searchList.add(i);
                  }
                }

                // Rebuild UI to show updated search results
                setState(() {
                  _searchList;
                });
              },
            )
                : const Text("Orbit"), // App name when not searching

            // Home icon on the left side of app bar
            leading: Icon(Icons.home),

            // Action buttons on the right side of app bar
            actions: [
              // ========== SEARCH TOGGLE BUTTON ==========
              IconButton(
                onPressed: () {
                  setState(() {
                    // Toggle search mode on/off
                    _isSearching = !_isSearching;
                  });
                },
                // Show different icon based on search state
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid // Clear icon when searching
                      : Icons.search, // Search icon when not searching
                ),
              ),

              // ========== PROFILE BUTTON ==========
              IconButton(
                onPressed: () {
                  // Navigate to user's profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me),
                    ),
                  );
                },
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),

          // ========== FLOATING ACTION BUTTON ==========
          // Button positioned at bottom-right of screen
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: FloatingActionButton(
              onPressed: () async {
                // Sign out from Firebase Authentication
                await APIs.auth.signOut();
                // Sign out from Google Sign-In
                await GoogleSignIn.instance.signOut();

                // Check if widget is still mounted before navigation
                if (!context.mounted) return;

                // Navigate to login screen and remove all previous routes
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Icon(Icons.add_comment_rounded),
            ),
          ),

          // ========== MAIN BODY - USER LIST ==========
          body: StreamBuilder(
            // Real-time stream of all users from Firebase
            stream: APIs.getAllUsers(),

            builder: (context, snapshot) {
              // Handle different connection states
              switch (snapshot.connectionState) {
              // Show loading indicator while waiting for data
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

              // Data is being streamed or stream completed
                case ConnectionState.active:
                case ConnectionState.done:
                // Extract documents from snapshot
                  final data = snapshot.data?.docs;

                  // Convert Firebase documents to ChatUser objects
                  _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

                  // Check if user list is not empty
                  if (_list.isNotEmpty) {
                    // ========== DISPLAY LIST OF USERS ==========
                    return ListView.builder(
                      // Show search results count if searching, otherwise show all users
                      itemCount: _isSearching ? _searchList.length : _list.length,

                      // Add padding at top of list
                      padding: EdgeInsets.only(top: mq.height * 0.01),

                      // Bouncing scroll effect (iOS style)
                      physics: BouncingScrollPhysics(),

                      // Build each user card
                      itemBuilder: (context, index) {
                        return ChatUserCard(
                          // Show user from search list if searching, otherwise from main list
                          user: _isSearching ? _searchList[index] : _list[index],
                        );
                      },
                    );
                  } else {
                    // ========== EMPTY STATE ==========
                    // Show message when no users are found
                    return const Center(
                      child: Text(
                        'No Connections Found!',
                        style: TextStyle(fontSize: 20),
                      ),
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