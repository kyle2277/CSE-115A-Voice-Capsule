import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voice_capsule/src/authentication.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ProfileSlide extends StatelessWidget{
  const ProfileSlide({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 16, top:25, right: 16),
        child: ListView(
          children: [
            const Text(
              "Profile",
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(
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
                        image: AssetImage("assets/images/zenslug_2.gif"),
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
                    child: const Icon(Icons.edit, color: Colors.white,)
                  ))
                ],
              ),
            ),
            const SizedBox(
              height:35,
            ),
            BuildTextField(
                labelText: "Full Name",
                placeHolder: myName ?? ""),
            BuildTextField(
                labelText: "Email",
                placeHolder: myEmail ?? ""),

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
}

class BuildTextField extends StatelessWidget{
  BuildTextField({Key? key, required this.labelText, required this.placeHolder}) : super(key: key);
  String labelText;
  String placeHolder;

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(bottom: 3),
            labelText: this.labelText,
            labelStyle: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: this.placeHolder,
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor
            )
        ),
      ),
    );
  }
}