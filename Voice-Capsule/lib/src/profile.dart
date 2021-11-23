import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voice_capsule/main.dart';
import 'package:voice_capsule/src/authentication.dart';

//Retrieves user email from database
var userEmail = firebaseUser!.email;

class ProfileSlide extends StatelessWidget{
  const ProfileSlide({Key? key}) : super(key: key);
  @override
  //Builds profile UI
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(left: 16, top:25, right: 16),
        child: ListView(
          children: [
            Text(
              "Profile",
              style: TextStyle(fontSize:25, fontWeight: FontWeight.w500),
            ),
            //SizedBox provides padding
            SizedBox(
              height:15,

            ),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 4,
                        color: Theme.of(context).scaffoldBackgroundColor
                      ),
                      boxShadow:
                          [BoxShadow(
                            spreadRadius: 2, blurRadius: 10,
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0,10)
                          )],
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        //Default user profile image
                        image: AssetImage('assets/images/zenslug.jpg'),
                        //image: NetworkImage("https://lh3.googleusercontent.com/a-/AAuE7mBjk23t3G5-YiQxEseXi6MLp7_CMtmp3d5PfHCD=s640-rw-il")
                      )
                    )
                  ),

                  //COMMENTED BELOW IS THE EDIT PROFILE PIC BUTTON UI
                  //THIS CODE IS FOR IF YOU WANT TO ADD EDIT FUNCTIONALITY -

                  // Positioned(
                  //     bottom:0,
                  //     right:0,
                  //     child: Container(
                  //     height: 40,
                  //     width: 40,
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       border: Border.all(
                  //         width:4,
                  //         color: Theme.of(context).scaffoldBackgroundColor,
                  //       ),
                  //       color: Colors.green,
                  //   ),
                  //   child: Icon(Icons.edit, color: Colors.white,)
                  // ))
                ],
              ),
            ),
            SizedBox(
              height:35,
            ),
            buildTextField("Email", userEmail!),

            //Logout Button
            TextButton(
            child : const Text('LOGOUT'),
            onPressed : () {
              ApplicationState().signOut();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginCard())
              );
            })
          ],
        ),
      ),
    );
  }
  //Method below builds the text field showing email. Can be used in the future
  //to show other text fields such as Full Name and password
  Widget buildTextField(String labelText, String placeholder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(bottom: 3),
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: placeholder,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          )),
    ),
    );
    }
  }






