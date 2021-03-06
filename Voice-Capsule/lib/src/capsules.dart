import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'playback.dart';
import 'voice_capsule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'utils.dart';
import 'authentication.dart';

/*
 * Capsule page UI and functions
 */

// Capsules Slide
// The page to open capsules
class CapsulesSlide extends StatefulWidget {
  const CapsulesSlide({Key? key}) : super(key: key);

  @override
  _CapsulesSlideState createState() => _CapsulesSlideState();
}

class _CapsulesSlideState extends State<CapsulesSlide> with SingleTickerProviderStateMixin {
  // List of available capsules
  List<VoiceCapsule> capsules = [];

  late AnimationController newCapsuleAnimationController;
  late Animation newCapsuleAnimation;

  // Initially load capsules from local .dat files
  Future<void> loadCapsules() async {
    print("Loading CAPSULES");
    Directory dir = Directory("$CAPSULES_DIRECTORY/${firebaseUser!.uid}");
    // If user directory doesn't exist, create it and return
    if(!await dir.exists()) {
      await dir.create();
      return;
    }
    for(var entity in dir.listSync(recursive: false)) {
      if(entity is File) {
        String fileName = basename(entity.path);
        String fileNameSplit = fileName.split('.').last;
        if(fileNameSplit == "data") {
          await VoiceCapsule.newCapsuleFromDataFile(entity.path).then((loadedCapsule) {
            if(loadedCapsule != null) {
              print("Loading capsule: ${loadedCapsule.localFileName}");
              if(!capsules.contains(loadedCapsule)) {
                setState(() {
                  capsules.insert(0, loadedCapsule);
                });
              }
            }
          });
        }
      }
    }
  }

  @override
  @mustCallSuper
  // Override widget initState to initialize animation and load capsules from local storage
  void initState() {
    newCapsuleAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    newCapsuleAnimationController.repeat(reverse: true);
    newCapsuleAnimation = Tween(begin: 0.95, end: 0.8).animate(newCapsuleAnimationController)..addListener(() {
      setState(() {});
    });
    loadCapsules();
    super.initState();
  }

  @override
  @mustCallSuper
  // Override widget dispose to terminate animation controller
  void dispose() {
    newCapsuleAnimationController.dispose();
    super.dispose();
  }

  // Check if any capsules available, if so download from database
  Future<void> checkForNewCapsules(BuildContext context) async {
    String myUID = FirebaseAuth.instance.currentUser!.uid;
    showToast_OK(context, "Loading...", duration:10000);
    await VoiceCapsule.checkForCapsules(myUID).then((pendingCapsules) async {
      if(pendingCapsules.isEmpty) {
        print("No available capsules");
        showToast_quick(context, "No new Voice Capsules", duration: 2);
        return;
      }
      bool modified = false;
      for(VoiceCapsule newCapsule in pendingCapsules) {
        print("Available Capsule:");
        print("Sender name: ${newCapsule.senderName}");
        print("Sender UID: ${newCapsule.senderUID}");
        print("Storage file path: ${newCapsule.firebaseStoragePath}");
        print("Local file name: ${newCapsule.localFileName}");
        print("Open Date/Time: ${newCapsule.openDateTime}");
        await newCapsule.fetchFromDatabase().then((success) {
          if(success) {
            modified = true;
            // add to list of capsules
            setState(() {
              capsules.insert(0, newCapsule);
            });
          }
        });
      }
      if(modified) {
        showToast_quick(context, "New Voice Capsules received!", duration: 2);
      } else {
        showToast_quick(context, "No new Voice Capsules", duration: 2);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Returns title of capsule depending on whether it has been opened yet
  String getCapsuleTitle(VoiceCapsule capsule) {
    if(capsule.opened) {
      return "Capsule from";
    } else {
      return "NEW Capsule from";
    }
  }

  // Color generator for new capsule glow animation
  Color getNewCapsuleColor(double lightness, BuildContext context) {
    HSLColor col = HSLColor.fromColor(Theme.of(context).primaryColor);
    col = col.withLightness(lightness);
    return col.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: capsules.length,
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey, width: 0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ListTile(
                    tileColor: capsules[index].opened ? Theme.of(context).dialogBackgroundColor : getNewCapsuleColor(newCapsuleAnimation.value, context),
                    trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.save_alt),
                            color: Colors.grey,
                            iconSize: 22,
                            onPressed: (() async {
                              VoiceCapsule selected = capsules[index];
                              await selected.saveToDownloads().then((success) {
                                if(success) {
                                  showToast_quick(context, "Voice Capsule saved to downloads folder", duration:2);
                                } else {
                                  showToast_quick(context, "Failed to download Voice Capsule", duration:2);
                                }
                              });
                            }),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.grey,
                            iconSize: 22,
                            onPressed: () async {
                              VoiceCapsule selected = capsules[index];
                              String message = "If you've already opened it, selecting Yes will permanently delete this Voice Capsule from ${selected.senderName}.";
                              bool? yes = await showAlertDialog_YESNO(context, "Are you sure?", message, textScale: 1.25);
                              if(yes!) {
                                await selected.delete().then((value) {
                                  setState(() {
                                    capsules.remove(selected);
                                    showToast_quick(context, "Voice Capsule deleted", duration:1);
                                  });
                                });
                              }
                            },
                          ),
                        ]
                    ),
                    title: Text(
                      getCapsuleTitle(capsules[index]),
                      textScaleFactor: 0.9,
                      style: TextStyle(
                        color: capsules[index].opened ? Colors.grey : Colors.black45,
                      ),
                    ),
                    subtitle: Text(
                      capsules[index].toString(),
                      textScaleFactor: 1.5,
                      style: TextStyle(
                        color: capsules[index].opened ? Colors.grey : Colors.black54,
                      ),
                    ),
                    onTap : () async {
                      VoiceCapsule capsule = capsules[index];
                      // If not opened, set as opened and delete from database
                      if(!capsule.opened) {
                        await capsule.writeOpenedToDataFile().then((value) async {
                          setState(() {
                            capsule.setOpened();
                          });
                          await capsules[index].deleteFromDatabase();
                        });
                      }
                      // print(capsule.firebaseStoragePath.runtimeType);
                      Navigator.push(
                        context,
                        // Send audio file to player using capsules[index]
                        MaterialPageRoute(builder: (context) => PlaybackScreen(capsule.localFileName)));
                    }
                ),
              );
            },
          ),
        ),
        RaisedButton(
          onPressed: () async {
            await checkForNewCapsules(context).then((value) {
            });
          },
          color: Theme.of(context).dialogBackgroundColor,
          highlightColor: Colors.grey[300],
          child: Text(
              "Refresh",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ]
    );
  }
}

// Page to play given audio file
class PlaybackScreen extends StatefulWidget {
  PlaybackScreen (this.localFileName);

  final String localFileName;

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Recording"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SimplePlayback(audioFileUrl: '$CAPSULES_DIRECTORY/${firebaseUser!.uid}/${widget.localFileName}', autoStart: true),
          ],
        ),
      ),
    );
  }
}
