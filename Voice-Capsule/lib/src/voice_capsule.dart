import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'utils.dart';

class VoiceCapsule {

  String senderUID;
  String receiverUID;
  DateTime openDateTime;
  // Todo: change from String to whatever the database object ID datatype is
  String capsuleID = "";
  // Todo: decide whether to reference local audio file by URL or load the bytes into the VoiceCapsule data structure
  String audioFileUrl;
  //Uint8List audioFileBytes = Uint8List(1024);
  // Firebase instances
  static final firebaseInstance = FirebaseFirestore.instance;
  static final User firebaseUser = FirebaseAuth.instance.currentUser!;
  VoiceCapsule(this.senderUID, this.receiverUID, this.openDateTime, this.audioFileUrl);

  // Store voice capsule in database
  // TODO: remove for merge with dev
  static Future<void> sendToDatabase() async {
    String downloadURL;
    Directory appDocDir = await getApplicationDocumentsDirectory();
    print(appDocDir.absolute.toString());
    String localFilePath = '/data/user/0/com.ucsc.voice_capsule/cache/outgoing_2021-11-18_20-57-03-403812.mp4';
    String storageFilePath = 'outgoing_2021-11-18_20-57-03-403812.mp4';
    firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
    firebase_storage.Reference ref = storage.ref().child(storageFilePath);
    firebase_storage.UploadTask uploadTask = ref.putFile(
      File(localFilePath),
      firebase_storage.SettableMetadata(
        contentType: "video/mp4",
      ),
    );
    uploadTask.then((res) async {
      String downloadURL = await res.ref.getDownloadURL();
      print(downloadURL);
    });
  }

  // Required before any database access functions
  void setCapsuleID(String id) {
    capsuleID = id;
  }

  // Returns a list of voice capsule IDs available for the given user to download
  static Future<List<Map<String, dynamic>>> checkForCapsules(String userID) async {

    List<Map<String, dynamic>> pendingCapsules = <Map<String, dynamic>>[];
    var queryResult = await firebaseInstance.collection("users").doc(firebaseUser.uid).collection("capsules").doc("pending_capsules").get();
    final Map<String, dynamic> map = queryResult.data()!;
    print("Capsules pending in database: ${map.length}");
    // For each capsules in the map, check if its open date has been surpassed
    for (String key in map.keys) {
      Map<String, dynamic> capsule = queryResult.get(key);
      String openDateTime_str = capsule['open_date_time'];
      DateTime curDateTime = DateTime.now();
      DateTime openDateTime = DateTime.parse(openDateTime_str);
      // If the current date and time is after the open date and time of the capsule, add it to the list of capsules to return
      print("Current date ($curDateTime) is after the open date ($openDateTime): ${curDateTime.isAfter(openDateTime)}");
      if (curDateTime.isAfter(openDateTime)) {
        //print("Adding capsule to list");
        pendingCapsules.add(capsule);
      }
    }
    print("Capsules available to open: ${pendingCapsules.length}");
    return pendingCapsules;
  }

  // Get voice note of given ID from the database
  // Must provide sender and receiver UIDs
  static Future<void> fetchFromDatabase(String fileName, String senderUID, String receiverUID) async {
    firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
    firebase_storage.Reference ref = storage.ref().child(fileName);
    String downloadURL = await ref.getDownloadURL();
    //http.Response downloadedData = await http.get(Uri.parse(downloadURL));
    List<String> fileNameSplit = fileName.split("outgoing");
    String saveFileName = "incoming${fileNameSplit[1]}";
    print(saveFileName);
    String saveURL = '/data/user/0/com.ucsc.voice_capsule/cache/$saveFileName';
    File saveFile = File(saveURL);
    if(saveFile.existsSync()) {
      await saveFile.delete();
    }
    await saveFile.create();
    firebase_storage.DownloadTask downloadFile = ref.writeToFile(saveFile);
  }

}