import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import '../../models/chat_user.dart';
import '../widgets/profile_image.dart';
import 'auth/login.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  // ✅ ADDED: Controllers for proper value tracking
  TextEditingController nameController = TextEditingController(); // ✅ FIX
  TextEditingController aboutController = TextEditingController(); // ✅ FIX

  @override
  void initState() {
    super.initState();

    // ✅ Assign values safely
    nameController.text = APIs.me.name;
    aboutController.text = APIs.me.about;
  }

  @override
  void dispose() {
    // ✅ ADDED: Dispose controllers
    nameController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Screen')),

        floatingActionButton: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: FloatingActionButton.extended(
              onPressed: () async {
                Dialogs.showLoading(context);
                await APIs.auth.signOut().then((value) async{
                  await GoogleSignIn.instance.signOut().then((value){
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
                  });
                });
                if (!context.mounted) return;
              },
              icon: Icon(Icons.logout),
              label: Text("Logout"),
            ),
          ),
        ),

        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width*0.05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(width: mq.width,height: mq.height*0.05,),
                Stack(
                  children: [
                    // Profile Picture Display Logic
                    _image != null
                        ? // 1. Show Local Preview: This shows the file immediately after picking
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * 0.3),
                      child: Image.file(
                        File(_image!),
                        width: mq.height * 0.2,
                        height: mq.height * 0.2,
                        fit: BoxFit.fill,
                      ),
                    )
                        : // 2. Show Server Image: Use APIs.me.image so it reflects updates instantly
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * 0.3),
                      child: CachedNetworkImage(
                        width: mq.height * 0.2,
                        height: mq.height * 0.2,
                        fit: BoxFit.fill,
                        // ✅ FIXED: Changed widget.user.image to APIs.me.image
                        imageUrl: APIs.me.image,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                      ),
                    ),

                    // Edit Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MaterialButton(
                        onPressed: () {
                          _showBottomSheet();
                        },
                        elevation: 1,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: const Icon(Icons.edit),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: mq.height*0.05,),

                Text(
                  widget.user.email,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),

                SizedBox(height: mq.height * .05),

                // ✅ CHANGED: Using controller instead of initialValue
                TextFormField(
                  controller: nameController, // ✅ FIX
                  validator: (val)=>val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'eg. Kaal Goel',
                    label: Text('Name'),
                  ),
                ),

                SizedBox(height: mq.height * .02),

                // ✅ CHANGED: Using controller instead of initialValue
                TextFormField(
                  controller: aboutController, // ✅ FIX
                  validator: (val)=>val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.info_outline, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'eg. Feeling Happy',
                    label: Text('About'),
                  ),
                ),

                SizedBox(height: mq.height * .05),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: Size(mq.width * .5, mq.height * .06),
                  ),
                  // Replace your ElevatedButton.icon onPressed with this:
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Dialogs.showLoading(context);

                      bool success = true;

                      if (_image != null) {
                        success = await APIs.updateProfileImage(File(_image!));
                      }

                      APIs.me.name = nameController.text;
                      APIs.me.about = aboutController.text;
                      await APIs.updateUserInfo();

                      if (!context.mounted) return;
                      Navigator.pop(context); // close loading

                      if (success) {
                        Dialogs.showSnackbar(context, 'Profile Updated Successfully ✅');
                      } else {
                        Dialogs.showSnackbar(context, '⚠️ Info saved but image upload failed');
                      }
                    }
                  },
                  icon: const Icon(Icons.edit, size: 28),
                  label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(){
    showModalBottomSheet(context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (_){
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(
          top: mq.height * .03,
          bottom: mq.height * .05,
        ),
        children: [
          const Text(
            'Pick Profile Picture',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),

          //for adding some space
          SizedBox(height: mq.height * .02),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  fixedSize: Size(mq.width * .3, mq.height * .15),
                ),
                onPressed: () async {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
               imageQuality: 70 // ✅ Fixed: Compresses to pass the 5MB check
                );
                if(image != null){
               setState(() { _image = image.path; });
               Navigator.pop(context);
               }
          }, child: Image.asset('assets/images/add_image.png'),),

              //take picture from camera button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  fixedSize: Size(mq.width * .3, mq.height * .15),
                ),
                // Inside _showBottomSheet for Camera
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70 // ✅ ESSENTIAL: Shrinks camera photo to pass the 5MB check
                  );
                  if (image != null) {
                    setState(() {
                      _image = image.path;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Image.asset('assets/images/camera.png'),
              ),
            ],
          ),

          
        ],
      );
    });

  }
}
