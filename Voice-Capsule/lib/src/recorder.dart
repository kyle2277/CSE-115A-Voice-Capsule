import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

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
  var _recorded_url = null;

  // Initializing the recorder and the player ----------------------------------

  @override
  void initState() {
    //recorder = FlutterSoundRecorder();
    openRecorder().then((value) {
      setState(() {
        print('INITIALIZING recorder');
        print(value);
        _recorderIsInitialized = value;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    recorder!.closeAudioSession();
    recorder = null;
    super.dispose();
  }

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

  void printSomething() {
    print('HELLO WORLD');
  }

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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SenderScreen()),
    );


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

  // Shows "snackbar" style popup with the given message and an OK button
  // todo Could probably be moved to a utils file at some point
  void showToast_OK(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        duration: const Duration(seconds:5),
        behavior: SnackBarBehavior.floating,
        content: Text(
            message,
            textAlign: TextAlign.center
        ),
        action: SnackBarAction(
            label: 'OK',
            onPressed: scaffold.hideCurrentSnackBar,
            textColor: Colors.purpleAccent
        ),
      ),
    );
  }

  // Shows "snackbar" style popup with the given message. Quickyl hides itself
  // after the given number of seconds
  void showToast_quick(BuildContext, String message, int time) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        duration: Duration(seconds: time),
        behavior: SnackBarBehavior.floating,
        content: Text(
            message,
            textAlign: TextAlign.center
        ),
      ),
    );
  }

  // Basic Recorder UI
  // todo fix pixel overflow at bottom of screen
  @override
  Widget build(BuildContext context) {
    return Column (
      //mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 200,
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
                showToast_quick(context, 'Started recording', 1);
              }
              if(recorder!.isStopped && _recorded_url != null) {
                showToast_quick(context, 'Stopped recording', 1);
                showToast_OK(context, 'Recording saved to: $_recorded_url');
              }
            });
          },
        ),
        Text(
          recorder!.isRecording ? 'Recording' : 'Record',
          textScaleFactor: 1.5,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 100,
        ),
      ],
    );
  }
}

// Page to send recording and other options
class SenderScreen extends StatelessWidget {
  const SenderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Recording"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {

          },
          child: Text('SEND'),
        ),
      ),
    );
  }
}
