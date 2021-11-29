import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as fireStorage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils.dart';
import 'authentication.dart';
import 'package:intl/intl.dart';

/*
Voice Capsules .data file format:
sender UID
receiver UID
open date/time
firebase storage path
local file name
 */

class VoiceCapsule {
  String senderName;
  String senderUID;
  String receiverName;
  String receiverUID;
  DateTime openDateTime;
  String firebaseStoragePath;
  String localFileName;
  bool opened;
  // Firebase instances
  static final firebaseInstance = FirebaseFirestore.instance;
  static final firebaseStorageInstance = fireStorage.FirebaseStorage.instance;
  VoiceCapsule(this.senderName, this.senderUID, this.receiverName, this.receiverUID, this.openDateTime, this.firebaseStoragePath, this.localFileName, this.opened);

  static Future<VoiceCapsule?> newCapsuleFromDataFile(String dataFilePath) async {
    File inputDataFile = File(dataFilePath);
    if(!await inputDataFile.exists()) {
      return null;
    }
    List<String> lines = await inputDataFile.readAsLines();
    String senderName = lines[0];
    String senderUID = lines[1];
    String receiverName = lines[2];
    String receiverUID = lines[3];
    DateTime openDateTime = DateTime.parse(lines[4]);
    String firebaseStoragePath = lines[5];
    String localFileName = lines[6];
    bool opened = lines.length == 8;
    return VoiceCapsule(senderName, senderUID, receiverName, receiverUID, openDateTime, firebaseStoragePath, localFileName, opened);
  }

  // Uploads the selected voice capsule into storage
  Future<void> uploadToStorage(DateTime time) async {

    // Get file path to the file that was just recorded
    String filePath = '$CAPSULES_DIRECTORY/recorded_file.mp4';
    File file = File(filePath);

    // Upload to the receiver's folder for fetching by the receiver
    fireStorage.UploadTask uploadTask = firebaseStorageInstance.ref()
        .child(firebaseStoragePath)
        .putFile(file);

    uploadTask.then((result) async {
      return true;
    });
  }

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
    final DateFormat formatterDB = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Obtain the current time at which the capsule is sent
    DateTime currentTime = DateTime.now();

    final String openTime = formatterDB.format(this.openDateTime);

    // Format is <who receives capsule>/outgoing_<who sends capsule>_<creation_time>.mp4
    final String capsuleName = 'outgoing_${this.senderUID}_${sanitizeString(currentTime.toString())}';
    // Set path to file in firebase storage
    firebaseStoragePath = "$receiverUID/$capsuleName.mp4";

    // Upload the voice capsule just recorded onto Firebase storage, using
    // the same time indicated earlier
    this.uploadToStorage(currentTime);

    // Add a new entry with the appropriate details to sent capsules
    sender_capsules.update(<String, dynamic>{
      capsuleName : {
        'send_date_time': DateTime.now().toString(),
        'open_date_time': openTime,
        'receiver_name': receiverName,
        'receiver_uid': receiverUID,
      },
    });

    // Add a new entry with the appropriate details to pending capsules
    receiver_capsules.update(<String, dynamic>{
      capsuleName : {
        'open_date_time': openTime,
        'sender_name': myName!,
        'sender_uid': senderUID,
        'storage_path': firebaseStoragePath,
      }
    });

    return true;
  }

  // Returns a list of voice capsule IDs available for the given user to download
  static Future<List<VoiceCapsule>> checkForCapsules(String userID) async {
    List<VoiceCapsule> pendingCapsules = <VoiceCapsule>[];
    var queryResult = await firebaseInstance
        .collection("users")
        .doc(firebaseUser!.uid)
        .collection("capsules")
        .doc("pending_capsules").get();
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
    String senderName = capsule['sender_name'];
    String senderUID = capsule['sender_uid'];
    DateTime openDateTime = DateTime.parse(capsule['open_date_time']);
    String firebaseStoragePath = capsule['storage_path'];
    String localFileName = "incoming${firebaseStoragePath.split("outgoing").last}";
    print("Local File Name: $localFileName");
    String receiverUID = FirebaseAuth.instance.currentUser!.uid;
    VoiceCapsule newCapsule = VoiceCapsule(senderName, senderUID, myName!, receiverUID, openDateTime, firebaseStoragePath, localFileName, false);
    String capsuleDatFileName = "${newCapsule.getCapsuleFilePath().split(".mp4").first}.data";
    print("CapsuleDatFileName: $capsuleDatFileName");
    File dataFile = File(capsuleDatFileName);
    // if dat file already exists, capsule doesn't need to be downloaded from database
    if(await dataFile.exists()) {
      return null;
    }
    await dataFile.create();
    String capsuleData = "$senderName\n$senderUID\n${myName!}\n$receiverUID\n${openDateTime.toString()}\n$firebaseStoragePath\n$localFileName";
    await dataFile.writeAsString(capsuleData);
    return newCapsule;
  }

  // Get voice note of given ID from the database
  // Must provide sender and receiver UIDs
  // Returns true if capsule downloaded from database, false otherwise
  Future<bool> fetchFromDatabase() async {
    fireStorage.Reference ref = firebaseStorageInstance.ref().child(firebaseStoragePath);
    String saveDirPath = '$CAPSULES_DIRECTORY/${firebaseUser!.uid}';
    // Ensure directory exists
    Directory dir = Directory(saveDirPath);
    if(!await dir.exists()) {
      await dir.create();
    }
    String saveFilePath = "$saveDirPath/$localFileName";
    File saveFile = File(saveFilePath);
    if(await saveFile.exists()) {
      return false;
    }
    await saveFile.create();
    fireStorage.DownloadTask downloadFile = ref.writeToFile(saveFile);
    return true;
  }

  // Deletes this voice capsule object from local storage
  Future<void> delete() async {
    print("Deleting $localFileName and associated data file...");
    // receiverUID should be current user UID
    String audioFilePath = getCapsuleFilePath();
    print(audioFilePath);
    String dataFilePath = audioFilePath.split(".mp4").first;
    dataFilePath += ".data";
    File audioFile = File(audioFilePath);
    File dataFile = File(dataFilePath);
    if(await audioFile.exists()) {
      await audioFile.delete();
    } else {
      print("Delete error: no audio file found.");
    }
    if(await dataFile.exists()) {
      await dataFile.delete();
    } else{
      print("Delete error: no data file found.");
    }
  }

  // Deletes voice capsule entry from Firestore Database and audio file from Firebase Storage
  Future<void> deleteFromDatabase() async {
    String databaseCapsuleName = "outgoing_${(localFileName.split("incoming_").last).split(".mp4").first}";
    CollectionReference all_users = firebaseInstance.collection('users');
    DocumentReference receiver_capsules = all_users
        .doc(receiverUID)
        .collection('capsules')
        .doc('pending_capsules');
    receiver_capsules.update(<String, dynamic>{
      databaseCapsuleName: FieldValue.delete()
    }).whenComplete(() {
      fireStorage.Reference ref = firebaseStorageInstance.ref().child(firebaseStoragePath);
      ref.delete();
    });
  }

  // Saves voice capsule audio file to device downloads folder
  // Android only
  Future<bool> saveToDownloads() async {
    var status = await Permission.storage.request();
    if(status != PermissionStatus.granted) {
      throw StoragePermissionException('Storage permission not granted');
    }
    String audioFilePath = getCapsuleFilePath();
    String saveFileName = "Voice-Capsule_${sanitizeString(senderName)}_${sanitizeString(openDateTime.toString())}.mp4";
    String saveFilePath = "$ANDROID_DOWNLOADS_PATH/$saveFileName";
    print("Want to save $localFileName to device Downloads folder...");
    //print("Download file name: $saveFileName");
    //print("Voice capsule path: $audioFilePath");
    //print("Download file path: $saveFilePath");
    File audioFile = File(audioFilePath);
    File saveFile = File(saveFilePath);
    // Append (x) to end of filename to make it unique if file already exists
    int i = 1;
    while(await saveFile.exists()) {
      RegExp splitPathRegExp = RegExp(r"\(.*\)\.mp4|\.mp4");
      saveFilePath = "${saveFilePath.split(splitPathRegExp).first}($i).mp4";
      saveFile = File(saveFilePath);
      i += 1;
    }
    print("Saving to $saveFilePath");
    if(!await audioFile.exists()) {  // Should never happen
      print("ERROR: Cannot download Voice Capsule, audio file DOES NOT EXIST.");
      return false;
    }
    await audioFile.copy(saveFilePath);
    return true;
    // try {
    //   await audioFile.copy(saveFilePath);
    //   return true;
    // } on FileSystemException catch(e) {
    //   print("ERROR: ${e.message}");
    //   return false;
    // }
  }

  // Sets 'opened' flag in the current VoiceCapsule object
  // Call after setOpenAsync()
  void setOpened() {
    opened = true;
  }

  // Sets 'opened' in current VoiceCapsule object's respective .data file
  Future<bool> writeOpenedToDataFile() async {
    if(opened) {
      return true;
    }
    String dataFilePath = "${getCapsuleFilePath().split(".mp4").first}.data";
    print("Data file path : $dataFilePath");
    File dataFile = File(dataFilePath);
    if(!await dataFile.exists()) {  // Should never happen
      print("ERROR: capsule .data file does not exist");
      return false;
    }
    dataFile.writeAsString("\nopened", mode: FileMode.append);
    return true;
  }

  String getCapsuleFilePath() {
    return "$CAPSULES_DIRECTORY/$receiverUID/$localFileName";
  }

  // String representation of a capsule is the sender's name
  // If sender is current user, return "Myself"
  String toString() {
    if(myName == null) {
      return senderName;
    } else {
      return senderName == myName ? "Myself" : senderName;
    }
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

// Storage permissions
class _StorageException implements Exception {
  final String _message;

  _StorageException(this._message);

  String get message => _message;
}

// Permission to access storage was not granted
class StoragePermissionException extends _StorageException {
  //  Permission to record was not granted
  StoragePermissionException(String message) : super(message);
}