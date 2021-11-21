import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:voice_capsule/src/voice_capsule.dart';
import 'authentication.dart';
import 'date_time_picker.dart';
import 'playback.dart';
import 'dart:collection';

import 'utils.dart';

/*
 * Class for recording audio from device microphone
 */

class SimpleRecorder extends StatefulWidget {
  SimpleRecorder({
    required this.contacts,
    // will we need to pass in the firebase instance to pass into send screen
    // through this argument?
  });
  // User contacts
  LinkedHashMap<String, String> contacts;
  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {

  static const int MAX_RECORDING_MINUTES = 1;
  // min * sec/min * ms/sec = ms
  static const int MAX_RECORDING_MILLIS = MAX_RECORDING_MINUTES * 60 * 1000;
  // Audio codec
  Codec _codec = Codec.aacMP4;
  String _filePath = 'recorded_file.mp4';
  // "?" makes nullable type
  FlutterSoundRecorder? recorder = FlutterSoundRecorder();
  bool _recorderIsInitialized = false;
  // Monitor for sound level, elapsed time
  StreamSubscription? _recorderSubscription;
  // Sound level being recorded, range 0-120
  double dbLevel = 0;
  int time = 0;
  // Path to output file
  var _recordedUrl = null;

  // Initializing the recorder and the player ----------------------------------

  @override
  void initState() {
    openRecorder().then((value) {
      _recorderSubscription = recorder!.onProgress!.listen((e) {
        setState(() {
          time = e.duration.inMilliseconds;
          if(recorder!.isRecording && time >= MAX_RECORDING_MILLIS) {
            stopRecording();
          }
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
    _recordedUrl = null;
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
        _recordedUrl = value;
      });
      print('File saved at: ${_recordedUrl}');
      if(recorder!.isStopped && _recordedUrl != null) {
        showToast_quick(context, 'Stopped recording', duration: 1);
        showToast_OK(context, 'Recording saved to: $_recordedUrl');
      }
    });

    // Open sending screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SenderScreen(contacts: widget.contacts, audioFileUrl: _recordedUrl)),
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
                  width: 15.0,
                  offset: 2.5,
                  maxHeight: 150.0,
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
              if(recorder!.isRecording && _recordedUrl == null) {
                showToast_quick(context, 'Started recording', duration: 1);
              }
              // Recording stopped toast located in stopRecording() function
            });
          },
        ),
        // Decibel level indicator
        // Text(
        //   recorder!.isRecording ? 'dB: ${((dbLevel * 100.0).floor() / 100)}' : '',
        //   textScaleFactor: 1.25,
        // ),
        // Recording text indicator
        Text(
          recorder!.isRecording ? 'Recording' : 'Record',
          textScaleFactor: 1.5,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Recording time elapsed indicator
        Text(
          recorder!.isRecording ? '${millisToTimestamp(time)} / 0$MAX_RECORDING_MINUTES:00.0' : '',
          textScaleFactor: 1.5,
        ),
      ],
    );
  }
}

// Page to send recording and other options
class SenderScreen extends StatefulWidget {
  SenderScreen({
    required this.contacts,
    required this.audioFileUrl,
    // will we need to pass in the firebase instance started in main to
    // ensure we can send something here when ready to send?
  });
  // List of contacts
  LinkedHashMap<String, String> contacts;
  List<String>? contactsNameList;
  String audioFileUrl;
  // Date/time selection
  DateTime? currentDateTimeSelection;
  // Recipient selection
  String? recipient;
  final dateTimeFormat = DateFormat("MM-dd-yyyy, hh:mm a");

  @override
  _SenderScreenState createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  //const SenderScreen({Key? key}) : super(key: key);

  @override
  @mustCallSuper
  void initState() {
    widget.contactsNameList = <String>["Myself"];
    for (String username in widget.contacts.keys) {
      if(username != "Myself") {
        widget.contactsNameList!.add(username);
      }
    }
    widget.recipient = widget.contactsNameList![0];
    super.initState();
  }

  // Must be able to update a user's sent capsules AND the receiver's
  // pending capsules
  void sendToDatabase(String senderID, String receiverID, String fileName) {
    // Grab reference to the users collection
    CollectionReference all_users = FirebaseFirestore.instance
        .collection('users');

    // Obtain references to the sending and pending documents for each side
    DocumentReference sender_capsules = all_users
        .doc(senderID)
        .collection('capsules')
        .doc('sent_capsules');
    DocumentReference receiver_capsules = all_users
        .doc(receiverID)
        .collection('capsules')
        .doc('pending_capsules');

    // Get creation time for unique identifier
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd_hh-mm-ss');
    final String cur_date_time = formatter.format(now);

    final String capsule_name = 'capsule_${firebase_user!.uid}_${cur_date_time}';
    final String open_time = widget.dateTimeFormat.format(widget.currentDateTimeSelection!);

    // Upload audio file to Firebase storage and obtain URL

    // Add a new entry with the appropriate details to sent capsules
    sender_capsules.update(<String, dynamic>{
      capsule_name : {
        'open_date_time': open_time,
        'receiver_uid': receiverID,
      },
    });

    // Add a new entry with the appropriate details to pending capsules
    receiver_capsules.update(<String, dynamic>{
      capsule_name : {
        'open_date_time': open_time,
        'sender_uid': senderID,
        'url': 'gs://something',
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Recording"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SimplePlayback(audioFileUrl: widget.audioFileUrl),
            //BasicDateTimeField(currentSelection: widget.currentSelection),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: DateTimeField(
                decoration: InputDecoration(hintText: 'No selection'),
                format: widget.dateTimeFormat,
                onShowPicker: (context, currentValue) async {
                  final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime(2100));
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                      TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                    );
                    DateTime fieldValue = DateTimeField.combine(date, time);
                    setState(() {
                      widget.currentDateTimeSelection = fieldValue;
                    });
                    return fieldValue;
                  } else {
                    setState(() {
                      widget.currentDateTimeSelection = currentValue ?? DateTime.now();
                    });
                    return currentValue;
                  }
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Selected date: ${widget.currentDateTimeSelection != null ? widget.dateTimeFormat.format(widget.currentDateTimeSelection!) : "No Selection"}',
              textScaleFactor: 1.5,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select recipient:',
                  textScaleFactor: 1.5,
                ),
                SizedBox(
                  width: 10.0,
                ),
                DropdownButton<String>(
                  value: widget.recipient,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(
                      color: Colors.purple,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.purple,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      widget.recipient = newValue!;
                    });
                  },
                  items: widget.contactsNameList!
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            textScaleFactor: 1.5,
                          ),
                        );
                      })
                      .toList(),
                ),
              ]
            ),
            OutlinedButton(
              child: Text('SEND'),
              onPressed: () {
                /*
                 TODO: Create a VoiceCapsule object and invoke sendToDatabase()
                  x Get senderID from widget.contacts["Myself"]
                  x Get recieverID from widget.contacts[widget.recipient]
                  x Get file name from widget.audioFileUrl
                  x Get capsule ID from database (not sure how yet)
                  **save url?
                */

                // if date time selection is null (not set), throw error

                String? senderID = widget.contacts["Myself"];
                String? receiverID = widget.contacts[widget.recipient];
                String? fileName = widget.audioFileUrl;

                // Send the parameters to the database for the sender
                // **also need to send parameters to database for receiver
                sendToDatabase(senderID!, receiverID!, fileName!);

                String message = "Sender: Myself\n"
                    "Sender UID: ${senderID}\n"
                    "Receiver: ${widget.contacts[receiverID]}\n"
                    "Receiver UID: ${receiverID}\n"
                    "Open Date/Time: ${widget.currentDateTimeSelection != null ? widget.dateTimeFormat.format(widget.currentDateTimeSelection!) : ""}\n\n"
                    "You have pressed send!";
                showAlertDialog_OK(context, message);
              },
            ),
          ],
        ),
      ),
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
