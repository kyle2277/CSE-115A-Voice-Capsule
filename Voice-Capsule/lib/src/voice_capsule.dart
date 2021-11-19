import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<bool> sendToDatabase() async {
    if(capsuleID.isEmpty) {
      return false;
    }
    // Todo: change to true once database logic added
    return false;
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
  static VoiceCapsule? fetchFromDatabase(String url, String senderUID, String receiverUID) {
    // Todo: get this info from the database
    String audioFileUrl = "";
    DateTime openDateTime = DateTime.now();
    return VoiceCapsule(senderUID, receiverUID, openDateTime, audioFileUrl);
  }

}