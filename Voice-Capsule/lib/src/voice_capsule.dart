import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voice_capsule/src/utils.dart';
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

  // Uploads the selected voice capsule into storage
  Future<void> uploadToStorage(DateTime time) async {
    // Get current instance of Firebase storage for the user
    firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

    // Get file path to the file that was just recorded
    String filePath = '/data/user/0/com.ucsc.voice_capsule/cache/recorded_file.mp4';
    File file = File(filePath);

    // Upload to the receiver's folder for fetching by the receiver
    firebase_storage.UploadTask uploadTask = storage.ref()
        .child('${this.receiverUID}/outgoing_${sanitizeString(time.toString())}.mp4')
        .putFile(file);

    uploadTask.then((result) async {
      return true;
    });
  }

  // Store voice capsule in database
  Future<bool> sendToDatabase() async {
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

    // Use open time to create a distinct name for the file uploaded
    final DateFormat formatter_db = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Obtain the current time at which the capsule is sent
    DateTime current_time = DateTime.now();

    final String open_time = formatter_db.format(this.openDateTime);

    // Format is <who receives capsule>/outgoing_<who sends capsule>_<creation_time>.mp4
    final String capsule_name = 'outgoing_${this.senderUID}_${sanitizeString(current_time.toString())}';

    // Upload the voice capsule just recorded onto Firebase storage, using
    // the same time indicated earlier
    this.uploadToStorage(current_time);

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
        'storage_path': '${receiverUID}/${capsule_name}.mp4',
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
  //
  // How should we get the date using this function? Should we at all?
  static VoiceCapsule? fetchFromDatabase(String capsuleID, String senderUID, String receiverUID) {
    // Todo: get this info from the database
    String audioFileUrl = "";
    DateTime openDateTime = DateTime.now();
    return VoiceCapsule(senderUID, receiverUID, openDateTime, audioFileUrl);
  }

}