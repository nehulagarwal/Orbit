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
                    //profile pic
                    _image!=null?
                        //local img
                    ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.3),
            child: Image.file(
              File(_image!),
              width: mq.height * 0.2,
              height: mq.height * 0.2,
              fit: BoxFit.fill,

            ),
          ) :

//img from server
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * 0.3),
                      child: CachedNetworkImage(
                        width: mq.height * 0.2,
                        height: mq.height * 0.2,
                        fit: BoxFit.fill,
                        imageUrl: widget.user.image,
                        placeholder:(context,url)=>CircularProgressIndicator(),
                        errorWidget:(context,url,error)=>CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MaterialButton(
                        onPressed: (){
                          // (image picker logic can go here)
                          _showBottomSheet();
                        },
                        elevation: 1,
                        shape: CircleBorder(),
                        color: Colors.white,
                        child: Icon(Icons.edit),
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
                  onPressed: () async {
                    if(_formKey.currentState!.validate()){

                      // ✅ CHANGED: Directly assign from controllers
                      APIs.me.name = nameController.text;
                      APIs.me.about = aboutController.text;

                      log("NEW NAME: ${APIs.me.name}"); // ✅ DEBUG
                      log("NEW ABOUT: ${APIs.me.about}");

                      await APIs.updateUserInfo();

                      Dialogs.showSnackbar(context,'Profile Updated Successfully');

                      log('inside validator');
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
                  // Pick an image.
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if(image!=null){
                    log('Image path: ${image.path} -- MimeType: ${image.mimeType} ');
                    setState(() {
                      _image=image.path;
                    });
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
                onPressed: () async {
                  final picker = ImagePicker();
                  // Pick an image.
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if(image!=null){
                    log('Image path: ${image.path} -- MimeType: ${image.mimeType} ');
                    setState(() {
                      _image=image.path;
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
