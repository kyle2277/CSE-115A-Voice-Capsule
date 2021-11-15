import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

class VoiceCapsule {

  String senderUID;
  String receiverUID;
  DateTime openDateTime;
  // Todo: change from String to whatever the database object ID datatype is
  String capsuleID = "";
  // Todo: decide whether to reference local audio file by URL or load the bytes into the VoiceCapsule data structure
  String audioFileUrl;
  //Uint8List audioFileBytes = Uint8List(1024);

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
  Future<List<String>> checkForCapsules(String userID) async {
    return <String>[];
  }

  // Get voice note of given ID from the database
  // Must provide sender and receiver UIDs
  static VoiceCapsule? fetchFromDatabase(String capsuleID, String senderUID, String receiverUID) {
    // Todo: get this info from the database
    String audioFileUrl = "";
    DateTime openDateTime = DateTime.now();
    return VoiceCapsule(senderUID, receiverUID, openDateTime, audioFileUrl);
  }

}