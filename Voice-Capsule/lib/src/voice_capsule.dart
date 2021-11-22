import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'utils.dart';

/*
Voice Capsules .data file format:
sender UID
receiver UID
open date/time
firebase storage path
local file name
 */

class VoiceCapsule {

  String senderUID;
  String receiverUID;
  DateTime openDateTime;
  String firebaseStoragePath;
  String localFileName;
  //Uint8List audioFileBytes = Uint8List(1024);
  // Firebase instances
  static final firebaseInstance = FirebaseFirestore.instance;
  static final User firebaseUser = FirebaseAuth.instance.currentUser!;
  VoiceCapsule(this.senderUID, this.receiverUID, this.openDateTime, this.firebaseStoragePath, this.localFileName);

  static Future<VoiceCapsule?> newCapsuleFromDataFile(String dataFilePath) async {
    File inputDataFile = File(dataFilePath);
    if(!await inputDataFile.exists()) {
      return null;
    }
    List<String> lines = await inputDataFile.readAsLines();
    String senderUID = lines[0];
    String receiverUID = lines[1];
    DateTime openDateTime = DateTime.parse(lines[2]);
    String firebaseStoragePath = lines[3];
    String localFileName = lines[4];
    return VoiceCapsule(senderUID, receiverUID, openDateTime, firebaseStoragePath, localFileName);
  }

  // Store voice capsule in database
  // TODO: remove for merge with dev
  static Future<void> sendToDatabase() async {
    String localFilePath = '${CAPSULES_DIRECTORY}outgoing_2021-11-18_20-57-03-403812.mp4';
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

  // Returns a list of voice capsule IDs available for the given user to download
  static Future<List<VoiceCapsule>> checkForCapsules(String userID) async {
    List<VoiceCapsule> pendingCapsules = <VoiceCapsule>[];
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
        // Create capsule and associated data
        await createCapsuleAndData(capsule).then((newCapsule) {
          if(newCapsule != null) {
            pendingCapsules.add(newCapsule);
          }
        });
      }
    }
    print("Capsules available to open: ${pendingCapsules.length}");
    return pendingCapsules;
  }

  // Adds new voice capsule object to capsules list and creates .dat file for it
  static Future<VoiceCapsule?> createCapsuleAndData(Map<String, dynamic> capsule) async {
    String senderUID = capsule['sender_uid'];
    DateTime openDateTime = DateTime.parse(capsule['open_date_time']);
    String firebaseStoragePath = capsule['storage_path'];
    String localFileName = "incoming${firebaseStoragePath.split("outgoing").last}";
    print("Local File Name: $localFileName");
    String receiverUID = FirebaseAuth.instance.currentUser!.uid;
    VoiceCapsule newCapsule = VoiceCapsule(senderUID, receiverUID, openDateTime, firebaseStoragePath, localFileName);
    String capsuleDatFileName = "$CAPSULES_DIRECTORY${localFileName.split('.').first}.data";
    print("CapsuleDatFileName: $capsuleDatFileName");
    File dataFile = File(capsuleDatFileName);
    // if dat file already exists, capsule doesn't need to be downloaded from database
    if(await dataFile.exists()) {
      return null;
    }
    await dataFile.create();
    String capsuleData = "$senderUID\n$receiverUID\n${openDateTime.toString()}\n$firebaseStoragePath\n$localFileName";
    await dataFile.writeAsString(capsuleData);
    return newCapsule;
  }

  // Get voice note of given ID from the database
  // Must provide sender and receiver UIDs
  // Returns true if capsule downloaded from database, false otherwise
  Future<bool> fetchFromDatabase() async {
    firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
    firebase_storage.Reference ref = storage.ref().child(firebaseStoragePath);
    String saveURL = '$CAPSULES_DIRECTORY$localFileName';
    File saveFile = File(saveURL);
    if(await saveFile.exists()) {
      return false;
    }
    await saveFile.create();
    firebase_storage.DownloadTask downloadFile = ref.writeToFile(saveFile);
    return true;
  }

  // TODO: change when creating final capsule UI
  String toString() {
    return localFileName;
  }

  // Override operators for comparing voice capsules
  @override
  bool operator ==(other) {
    return (other is VoiceCapsule) && other.localFileName == localFileName &&
        other.firebaseStoragePath == firebaseStoragePath;
  }

  @override
  int get hashCode => localFileName.hashCode ^ firebaseStoragePath.hashCode;

}