import 'dart:io';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;

  @override
  void initState() {

    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGoogleButtonClick() {
    Dialogs.showLoading(context);
    _signInWithGoogle().then((user) async{
      Navigator.pop(context);
      if(user!=null){
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');
        if((await APIs.userExists())){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()), // ✅ changed to HomeScreen
          );
        }
        else{
          APIs.createUser().then((value){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()), // ✅ changed to HomeScreen
            );
          });
        }

        }



    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    // Initialize with your web client ID
    try{
      await InternetAddress.lookup('google.com');
      await GoogleSignIn.instance.initialize(
        serverClientId: '64908334976-e0ess2lh03lmmlaqb3i48qre6tm639ih.apps.googleusercontent.com', // from Firebase Console
      );

      final GoogleSignInAccount googleUser =
      await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await APIs.auth.signInWithCredential(credential);
    }
    catch(e){
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, "Something went wrong (Check Internet)");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome to Orbit"),
      ),
      body: Stack(
        children: [

          // Logo
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            top: _isAnimate ? mq.height * .15 : mq.height * .05,
            left: mq.width * .25,
            width: mq.width * .5,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _isAnimate ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                scale: _isAnimate ? 1.0 : 0.3,
                child: Image.asset('assets/images/Orbit_icon.png'),
              ),
            ),
          ),

          // Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            bottom: _isAnimate ? mq.height * .15 : mq.height * .05,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .06,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _isAnimate ? 1.0 : 0.0,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                  shape: const StadiumBorder(),
                  elevation: 1,
                ),
                icon: Image.asset(
                  'assets/images/google.png',
                  height: mq.height * .03,
                ),
                onPressed: _handleGoogleButtonClick,
                label: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(text: 'Login with '),
                      TextSpan(
                        text: 'Google',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}