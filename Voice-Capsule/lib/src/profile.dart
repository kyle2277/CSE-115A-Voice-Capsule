import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ProfileSlide extends StatelessWidget{
  const ProfileSlide({Key? key}) : super(key: key);
  @override
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
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage("https://lh3.googleusercontent.com/a-/AAuE7mBjk23t3G5-YiQxEseXi6MLp7_CMtmp3d5PfHCD=s640-rw-il")
                      )
                    )
                  ),
                  Positioned(
                      bottom:0,
                      right:0,
                      child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width:4,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        color: Colors.green,
                    ),
                    child: Icon(Icons.edit, color: Colors.white,)
                  ))
                ],
              ),
            ),
            SizedBox(
              height:35,
            ),
            buildTextField("Full Name", "Marianna Marcelline"),
            buildTextField("Email", "marianna.marcelline@gmail.com"),

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






