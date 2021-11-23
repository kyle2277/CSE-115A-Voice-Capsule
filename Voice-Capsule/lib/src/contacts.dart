import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:voice_capsule/src/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * Contacts page
 */

User? firebaseUser; // for obtaining uid

// Friends list
class ContactsSlide extends StatefulWidget {
  const ContactsSlide({Key? key}) : super(key: key);

  @override
  _ContactsSlideState createState() => _ContactsSlideState();
}

// TODO implement refesh button
class _ContactsSlideState extends State<ContactsSlide>{
  Map<String, dynamic> friends = <String, dynamic>{}; // list of contacts

  @override
  void initState() {
    firebaseUser = FirebaseAuth.instance.currentUser!; // instantiate the logged in user
    buildFriendsList(); // populate list of contacts
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
              child: friends.length==0 ? Header('No friends yet...') : ListView.builder(
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
        ]
    );
  }

  // Populate the friend list
  Future<void> buildFriendsList() async {
    var thisUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser!.uid).get(); // get this user's document
    friends = thisUser['contacts']; // get this user's friend's list
    setState((){}); // refresh
  }
}

// ensure that your friend exists
// TODO make this able to handle sending a request to yourself or someone who is already a friend
Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
    ) async {
  try {
    var methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email); // find email
    if (!methods.contains('password')) { // should this email not exist
      errorCallback(FirebaseAuthException(
          code:'invalid-email',
          message: 'This email is does not currently belong to a user account.'));
    }
  } on FirebaseAuthException catch (e) {
    errorCallback(e); // send the error message
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

class _FriendFormState extends State<FriendForm> {
  final _formKey = GlobalKey<FormState>(); // global key that uniquely identifies the Form widget
  final _controller = TextEditingController(); // text from text field

  // todo make sure you don't send yourself or a known contact a request
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
                  return 'Enter their email address to continue';
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
                      verifyEmail( // make sure that email exists
                        otherEmail,
                              (e) => _showErrorDialog(context, 'Invalid email', e),
                      ).then((value) async{ // now, we send
                        var allUsers = await FirebaseFirestore.instance
                            .collection('add_friends')
                            .doc('all_users').get(); // document containing all usernames,emails,uids
                        Map<String,dynamic> allUsersMap = allUsers.data()!; // obtaining it in map form

                        var otherUserUid = allUsersMap[otherEmail].values.toList();
                        var otherUserPage = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserUid[0]).get(); // other user's doc containing friends,pending requests, etc
                        Map <String, dynamic> requestMap = otherUserPage['requests']; // their pending requests

                        var thisUserRef = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(firebaseUser!.uid).get(); // this user's doc
                        var thisUsername = allUsersMap[thisUserRef['email']].keys.toList(); // this user's username

                        requestMap[thisUserRef['email']] = thisUsername[0]; // add this user to other user's requests
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserUid[0]).update({
                          'requests' : requestMap
                        }); // push to data base
                        // TODO implement nav to main screen
                      });
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

  // Sends error messages
  void _showErrorDialog(BuildContext context, String title, Exception e) {
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
                  '${(e as dynamic).message}',
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