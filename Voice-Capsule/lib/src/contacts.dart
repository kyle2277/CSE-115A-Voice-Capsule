import 'package:flutter/material.dart';
import 'package:voice_capsule/src/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';
import 'authentication.dart';
import 'utils.dart';

/*
 * Contacts page
 */

// Mapping of friends' names to friends' UIDs
LinkedHashMap<String, String> currentUserContacts = LinkedHashMap<String, String>();
// Mapping of friends' names to friends' emails
Map<String, dynamic> friends = <String, dynamic>{};

// Friends list
class ContactsSlide extends StatefulWidget {
  const ContactsSlide({Key? key}) : super(key: key);

  @override
  _ContactsSlideState createState() => _ContactsSlideState();
  // Fetch contacts for given userID from database

  // Populate both friends maps
  static Future<void> populateUserContacts({bool newUser = false}) async {
    currentUserContacts.clear();
    currentUserContacts["Myself"] = firebaseUser!.uid;
    // Get user's contacts from firestore database
    var thisUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser!.uid).get();
    friends = thisUserDoc.data()!['contacts'];
    // If new user, don't parse empty friends list
    if(newUser) {
      return;
    }
    var allUsersDoc = await FirebaseFirestore.instance
        .collection('add_friends')
        .doc('all_users').get();
    for(String friendEmail in friends.keys) {
      String? friendName = friends[friendEmail];
      if(friendName == null) {
        continue;
      }
      Map<String, dynamic> friendInfoMap = allUsersDoc.data()![friendEmail];
      String? friendUID = friendInfoMap[friendName];
      if(friendUID == null) {
        continue;
      }
      currentUserContacts[friendName] = friendUID;
    }
  }
}

class _ContactsSlideState extends State<ContactsSlide>{

  // constructor
  @override
  void initState() {
    ContactsSlide.populateUserContacts(); // populate list of contacts
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children : [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                StyledButton(
                  child : const Text('Add Friends'),
                  onPressed : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute( // navigate to AddFriendsScreen
                            builder: (context) => const AddFriendsScreen()
                        )
                    );
                  },
                ),
                const SizedBox(width: 16),
                StyledButton(
                  child : const Text('Friend Requests'),
                  onPressed : () async{
                    var thisUser = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(firebaseUser!.uid).get(); // get this user's document

                    Navigator.push( // push to the request page
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendRequestScreen(
                              friendRequests:thisUser['requests'], // pass this user's pending requests
                          ),
                        )
                      );
                    },
                ),
              ]
          ),
          Expanded( // actual list of friends
              child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    String email = friends.keys.elementAt(index); // get a specific friend's info
                    return Card(
                        child: ListTile(
                          title : Text(friends[email]), // friend name
                          subtitle : Text(email), // friend email
                        )
                    );
                  }
                  )
          ),
          RaisedButton(
            onPressed: () async {
              await ContactsSlide.populateUserContacts().then((value) async {
                // Refresh send page contacts list
              });
            },
            color: Colors.grey[300],
            highlightColor: Colors.grey[300],
            child: const Text("Refresh"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ]
    );
  }
}

// Page to add friends
class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({Key? key}) : super(key: key);

  @override
  _AddFriendsState createState() => _AddFriendsState();
}

class _AddFriendsState extends State<AddFriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add Friends'),
          centerTitle: true,
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Column (
            mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Header("Type your friend's email"),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: FriendForm(), // the text field and corresponding button
              ),
            ],
          ),
        ),
    );
  }
}

// Form that belongs on AddFriends
class FriendForm extends StatefulWidget {
  const FriendForm({Key? key}) : super(key: key);

  @override
  _FriendFormState createState() => _FriendFormState();
}

class CustomException implements Exception {
  String title;
  String message;
  CustomException(this.title, this.message);
}

class _FriendFormState extends State<FriendForm> {
  final _formKey = GlobalKey<FormState>(); // global key that uniquely identifies the Form widget
  final _controller = TextEditingController(); // text from text field

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextFormField( // text field
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter their email',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter an email address to continue';
                }
                return null;
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 30),
                child: StyledButton( // send button
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) { // make sure not empty
                      String otherEmail = _controller.text; // email we want to send to
                      var thisUserRef = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(firebaseUser!.uid).get(); // this user's doc

                      var check = await verifyEmail(
                          otherEmail,
                          thisUserRef['email'],
                          thisUserRef['contacts'],
                          thisUserRef['requests']
                      ); // do sanity checks

                      if(check == true) { // now we can send
                        var allUsers = await FirebaseFirestore.instance
                            .collection('add_friends')
                            .doc('all_users')
                            .get(); // document containing all usernames,emails,uids
                        Map<String, dynamic> allUsersMap = allUsers
                            .data()!; // obtaining it in map form

                        var otherUserUid = allUsersMap[otherEmail].values
                            .toList(); // get uid
                        var otherUserPage = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserUid[0])
                            .get(); // other user's doc containing friends,pending requests, etc
                        Map <String,
                            dynamic> requestMap = otherUserPage['requests']; // their pending requests

                        var thisUsername = allUsersMap[thisUserRef['email']]
                            .keys.toList(); // this user's username
                        requestMap[thisUserRef['email']] = thisUsername[0]; // add this user to other user's requests
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserUid[0]).update({
                          'requests': requestMap
                        }); // push to database
                        showToast_quick(context, "Friend request sent!");
                        Navigator.of(context).pop(); // return to original screen
                      }
                    }
                  },
                  child: const Text('REQUEST'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ensure that your friend exists, they are not already a contact, they are not yourself,
  // and you dont have an outstanding request from them
  Future<bool> verifyEmail(
      String otherEmail,
      String thisEmail,
      Map<String,dynamic> thisContacts,
      Map<String,dynamic> thisRequests,
      ) async {
    try {
      try{ // check if formatting is good
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(otherEmail); // try email
      } on FirebaseAuthException catch (e) {
        throwException('Invalid email','The email address is badly formatted.');
      }

      if(otherEmail ==  thisEmail){ // check if same person
        throwException('Invalid email','You cannot add yourself.');
      }

      var methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(otherEmail); // find email
      if(methods.contains('password') == false){ // check other exists
        throwException('Invalid email','This user does not exist.');
      }

      if(thisContacts[otherEmail] != null){ // check if friend
        throwException('Invalid email','You are already friends.');
      }

      if(thisRequests[otherEmail] != null){ // check if in your requests
        throwException('Invalid email','You already have a request from them.');
      }
    } on CustomException catch (e){
      _showErrorDialog(context,e.title,e.message);
      return false;
    }
    return true;
  }

  // creates the exception
  void throwException(String title,String message) {
    throw CustomException(title,message);
  }

  // Sends error messages
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog( // holds the error message and exit button
          title: Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text( // the message obtained from verifyEmail()
                  message,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            StyledButton( // 'ok' button
              onPressed: () {
                Navigator.of(context).pop(); // return to original screen
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Page for friend requests
class FriendRequestScreen extends StatefulWidget {
  FriendRequestScreen ({ Key? key, required this.friendRequests }): super(key: key);
  final Map<String,dynamic> friendRequests; // list of requests sent to us from contacts page

  @override
  _FriendRequestState createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded( // list of pending requests
                child:
                widget.friendRequests.length==0 ? Header('No Friend Requests') : ListView.builder(
                    itemCount: widget.friendRequests.length,
                    itemBuilder: (context, index) {
                      String email = widget.friendRequests.keys.elementAt(index); // other user's email
                      return Card(
                          child: ListTile(
                            title : Text(widget.friendRequests[email]), // other user's username
                            subtitle : Text(email), // email
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton( // accept button
                                    onPressed: () async{
                                      // push other user contact to this user friend list
                                      var thisUserDoc = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(firebaseUser!.uid).get(); // get this user's document
                                      Map <String, dynamic> thisUserContacts = thisUserDoc['contacts']; // obtain contacts
                                      thisUserContacts[email] = widget.friendRequests[email]; // add new contact
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(firebaseUser!.uid).update({
                                        'contacts' : thisUserContacts
                                      }); // push new contact list to db

                                      // remove other user from this user request list
                                      widget.friendRequests.remove(email); // remove user from request list locally
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(firebaseUser!.uid).update({
                                        'requests' : widget.friendRequests
                                      }); // now push change

                                      // now add this user to other user's friends
                                      var allUsers = await FirebaseFirestore.instance
                                          .collection('add_friends')
                                          .doc('all_users').get(); // document containing all usernames,emails,uids
                                      Map<String,dynamic> allUsersMap = allUsers.data()!; // obtaining it in map form

                                      var otherUserUid = allUsersMap[email].values.toList();
                                      var otherUserPage = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(otherUserUid[0]).get(); // other user's doc containing friends,pending requests, etc
                                      var thisUsername = allUsersMap[thisUserDoc['email']].keys.toList();

                                      Map <String, dynamic> otherUserContacts = otherUserPage['contacts']; // their contacts
                                      otherUserContacts[thisUserDoc['email']] = thisUsername[0]; // add new contact

                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(otherUserUid[0]).update({
                                        'contacts' : otherUserContacts
                                      }); // now push change
                                      //
                                      // // TODO make sure when you go back, friends list is already refreshed
                                      showToast_quick(context, "Friend request accepted");
                                      setState((){}); // refresh
                                    },
                                    icon: Icon(Icons.check)),
                                IconButton( // reject request
                                    onPressed: () async {
                                      widget.friendRequests.remove(email); // remove user from request list locally
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(firebaseUser!.uid).update({
                                        'requests' : widget.friendRequests
                                      }); // now push change
                                      showToast_quick(context, "Friend request deleted");
                                      setState((){}); // refresh
                                    },
                                    icon: Icon(Icons.cancel)),
                              ],
                            ),
                          )
                      );
                    }
                )
            ),
          ],
        ),
      ),
    );
  }
}