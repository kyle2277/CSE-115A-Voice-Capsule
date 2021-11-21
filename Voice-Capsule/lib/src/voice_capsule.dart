import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'date_time_picker.dart';


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
    // if(capsuleID.isEmpty) {
    //   return false;
    // }

    // Grab reference to the users collection
    CollectionReference all_users = FirebaseFirestore.instance
        .collection('users');

    // Obtain references to the sending and pending documents for each side
    DocumentReference sender_capsules = all_users
        .doc(this.senderUID)
        .collection('capsules')
        .doc('sent_capsules');
    DocumentReference receiver_capsules = all_users
        .doc(this.receiverUID)
        .collection('capsules')
        .doc('pending_capsules');

    // Get creation time for unique identifier
    final DateTime now = DateTime.now();
    final DateFormat formatter_file = DateFormat('yyyy-MM-dd_hh-mm-ss');
    final DateFormat formatter_db = DateFormat('yyyy-MM-dd HH:mm:ss');

    final String cur_date_time = formatter_file.format(now);
    final String open_time = formatter_db.format(this.openDateTime);

    final String capsule_name = 'capsule_${firebase_user!.uid}_${cur_date_time}';

    // Upload audio file to Firebase storage and obtain URL

    // Add a new entry with the appropriate details to sent capsules
    sender_capsules.update(<String, dynamic>{
      capsule_name : {
        'open_date_time': open_time,
        'receiver_uid': receiverUID,
      },
    });

    // Add a new entry with the appropriate details to pending capsules
    receiver_capsules.update(<String, dynamic>{
      capsule_name : {
        'open_date_time': open_time,
        'sender_uid': senderUID,
        'url': 'gs://something',
      }
    });

    return true;
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