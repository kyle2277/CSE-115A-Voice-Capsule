import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utils.dart';

/*
 * Class for recording audio from device microphone
 */

class SimpleRecorder extends StatefulWidget {
  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {

  Codec _codec = Codec.aacMP4;
  String _filePath = 'recorded_file.mp4';
  // "?" makes nullable type
  FlutterSoundRecorder? recorder = FlutterSoundRecorder();
  bool _recorderIsInitialized = false;
  // Monitor for sound level, elapsed time
  StreamSubscription? _recorderSubscription;
  // Sound level being recorded, range 0-120
  double dbLevel = 0;
  int time =0;
  // Path to output file
  var _recorded_url = null;

  // Initializing the recorder and the player ----------------------------------

  @override
  void initState() {
    openRecorder().then((value) {
      _recorderSubscription = recorder!.onProgress!.listen((e) {
        setState(() {
          time = e.duration.inMilliseconds;
          if(e.decibels != null) {
            dbLevel = e.decibels as double;
          } else {
            dbLevel = 0;
          }
        });
      });
      recorder!.setSubscriptionDuration(const Duration(milliseconds:100));
      setState(() {
        print('INITIALIZING recorder');
        print(value);
        _recorderIsInitialized = value;
      });
    });
    super.initState();
  }

  @override
  // Close recorder
  void dispose() {
    recorder!.stopRecorder();
    closeRecorderSubscription();
    recorder!.closeAudioSession();
    recorder = null;
    super.dispose();
  }

  // Cancel monitor of recorder
  void closeRecorderSubscription() {
    if(_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  // Initialize recorder
  Future<bool> openRecorder() async {
    var status = await Permission.microphone.request();
    if(status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await recorder!.openAudioSession();
    if(!await recorder!.isEncoderSupported(_codec)) {
      return false;
    }
    print('Recorder state: $recorder');
    return true;
  }

  // Recording and playback ----------------------------------------------------

  Future<bool> record() async {
    print('START recording');
    // Clear path to last recorded file
    _recorded_url = null;
    await recorder!.startRecorder(
      toFile: _filePath,
      codec: _codec,
    )
        .then((value) {
          setState(() {
          });
    });
    return true;
  }

  Future<bool> stopRecording() async {
    print('STOP recording');
    await recorder!.stopRecorder().then((value) {
      setState(() {
        _recorded_url = value;
      });
      print('File saved at: ${_recorded_url}');
    });
    return true;
  }

  // UI functions --------------------------------------------------------------

  // Return type = nullable function
  // If not recording, return start record function. If recording, return
  // stop recording function
  Future<bool> Function()? getRecorderFunction() {
    if(!_recorderIsInitialized) {
      print('ERROR: Recorder not initialzed');
      return null;
    }
    print('Recorder is stopped: ${recorder!.isStopped}');
    return recorder!.isStopped ? record : stopRecording;
  }

  // Basic Recorder UI
  // todo fix pixel overflow at bottom of screen
  @override
  Widget build(BuildContext context) {
    return Column (
      //mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 200,
          width: 200,
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual audio level indicator
              CustomPaint(
                // Read as ternary operator
                painter: recorder!.isRecording ? AudioLevelIndicator(
                  numBars: 7,
                  dbLevel: dbLevel,
                  width: 10.0,
                  offset: 2.5,
                  maxHeight: 200.0,
                  scaleFactor: 0.6,
                ) : null,
              ),
            ],
          ),
        ),
        IconButton(
          splashRadius: 60,
          iconSize: 80.0,
          color: Colors.red[500],
          icon: recorder!.isStopped ? Icon(Icons.circle_rounded) : Icon(Icons.stop_circle_outlined),
          tooltip: recorder!.isRecording ? 'Tap to stop recording' : 'Tap to start recording',
          onPressed: () {
            getRecorderFunction()!.call().then((value) {
              if(recorder!.isRecording && _recorded_url == null) {
                showToast_quick(context, 'Started recording', duration: 1);
              }
              if(recorder!.isStopped && _recorded_url != null) {
                showToast_quick(context, 'Stopped recording', duration: 1);
                showToast_OK(context, 'Recording saved to: $_recorded_url');
              }
            });
          },
        ),
        Text(
          recorder!.isRecording ? 'dB: ${((dbLevel * 100.0).floor() / 100)}' : '',
          textScaleFactor: 1.25,
        ),
        Text(
          recorder!.isRecording ? 'Recording' : 'Record',
          textScaleFactor: 1.5,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Time indicator
        Text(
          recorder!.isRecording ? '${(((time)).floor()/1000)}' : '',
          textScaleFactor: 1.5,
        ),
      ],
    );
  }
}

// Class for creating a vertical bar-style audio level indicator
// Parameter numBars will be made an odd number if passed an even number
class AudioLevelIndicator extends CustomPainter {
  AudioLevelIndicator({
    required this.numBars,
    required this.dbLevel,
    this.width = 10.0,
    this.offset = 2.5,
    this.maxHeight = 150.0,
    this.scaleFactor = 0.6,
    this.cornerRadius = 4.0,
  });

  // Number of vertical bars in the indicator
  int numBars;
  // Source of decibel level
  double dbLevel;
  // Fixed width of a single drawn rectangle, default value 10.0
  double width;
  // Horizontal offset of drawn rectangles (space between them), default value 2.5
  double offset;
  // Max height of drawn rectangle, default value 100.0
  double maxHeight;
  // Factor of falloff of outer bar height, default value 0.5
  double scaleFactor;
  // Corner radius of bars, default value 2.0
  double cornerRadius;
  // Max decibel level
  final double DB_MAX = 120.0;

  // Draws outer bars increasing in height or decreasing
  // Use named parameter when calling
  void _drawOuterBars(Canvas canvas, Paint paint, {bool increasing = true}) {
    int numOuterBars = (numBars / 2.0).floor();
    for(int i = 1; i <= numOuterBars; i++) {
      double scaledMaxHeight = (maxHeight * (pow(scaleFactor, i)));
      double scaledHeight = (dbLevel * scaledMaxHeight) / DB_MAX;
      double horizontalOffset;
      if(increasing) {
        horizontalOffset = (-width/2) - (i * (width + offset));
      } else {
        horizontalOffset = (-width/2) + (i * (width + offset));
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(Offset(horizontalOffset, 0) & Size(width, -(scaledHeight)), Radius.circular(cornerRadius)),
          paint,
      );
    }
  }

  // Draw indicator on UI
  @override
  void paint(Canvas canvas, Size size) {
    // Bar style
    var paint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.fill;
    // Make numBars odd
    if(numBars % 2 != 1) {
      numBars += 1;
    }
    // Draw outer left bars (increasing in height left to right)
    _drawOuterBars(canvas, paint, increasing: true);
    // Draw center bar
    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset((-width/2), 0) & Size(width, -((dbLevel * maxHeight) / DB_MAX)), Radius.circular(cornerRadius)),
        paint,
    );
    // Draw outer right bars (decreasing in height left to right)
    _drawOuterBars(canvas, paint, increasing: false);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}