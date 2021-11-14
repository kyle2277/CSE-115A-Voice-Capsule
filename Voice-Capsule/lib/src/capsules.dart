import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'playback.dart';

import 'utils.dart';

/*
 * Capsules page
 */

// Capsules Slide
// The page to open capsules
class CapsulesSlide extends StatefulWidget {
  const CapsulesSlide({Key? key}) : super(key: key);

  @override
  _CapsulesSlideState createState() => _CapsulesSlideState();
}


class _CapsulesSlideState extends State<CapsulesSlide>{
  static const List<String> capsules = ['recorded_file.mp4','recorded_file.mp4','recorded_file.mp4']; // list of available capsules

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: capsules.length,
      itemBuilder: (context, index) {
        return Card(
            child: ListTile(
              title:Text(capsules[index]) ,
              onTap : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaybackScreen()),
                );
              }
            )
        );
      },
    );
  }
}

// Page to send recording and other options
class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Recording"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SimplePlayback(),
          ],
        ),
      ),
    );
  }
}
