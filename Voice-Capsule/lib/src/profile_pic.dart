import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePic extends StatelessWidget{
  const ProfilePic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return SizedBox(
      height:155,
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        children: [CircleAvatar(
          backgroundImage: AssetImage("blank_profile_pic.png"),
        ),
        ],
      ),
    );
  }
}