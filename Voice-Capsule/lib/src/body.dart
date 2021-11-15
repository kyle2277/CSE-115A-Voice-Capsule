import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voice_capsule/src/profile_pic.dart';


class Body extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        ProfilePic(),
        SizedBox(height: 2),
        //Search Bar - UI - not functioning, just for layout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
          child: FlatButton(
            padding: EdgeInsets.all(20),
            shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.grey,
            onPressed: () {},
            child: Row(
              children: [],
            ),
          ),
        ),
      ],
    );

  }
}