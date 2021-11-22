import 'package:flutter/material.dart';
import 'package:voice_capsule/src/playback.dart';

/*
 * Contacts page
 */

// Contacts Slide
// Friends list
class ContactsSlide extends StatefulWidget {
  const ContactsSlide({Key? key}) : super(key: key);

  @override
  _ContactsSlideState createState() => _ContactsSlideState();
}

class _ContactsSlideState extends State<ContactsSlide>{
  static const List<String> friends = ['Jovita','Kyle','Daniel','Marianna','Ricardo']; // list of friends

  @override
  Widget build(BuildContext context) {
    return Column(
        children : [
          TextButton(
            child : const Text('Add Friends'),
            onPressed : () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFriendsScreen())
              );
            },
          ),

          Expanded(
              child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return Card(
                        child: ListTile(
                            title : Text(friends[index])
                        )
                    );
                  }
              )
          ),
          TextButton(
            child : const Text('Friend Requests'),
            onPressed : () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FriendRequestScreen())
              );
            },
          ),
        ]
    );
  }
}

// Page to add friends
class AddFriendsScreen extends StatelessWidget {
  const AddFriendsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friends"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

          ],
        ),
      ),
    );
  }
}

// Page showing Friend Requests
class FriendRequestScreen extends StatelessWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

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

          ],
        ),
      ),
    );
  }
}