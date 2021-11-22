import 'package:flutter/material.dart';
import 'package:voice_capsule/src/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                StyledButton(
                  child : const Text('Add Friends'),
                  onPressed : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddFriendsScreen())
                    );
                    },
                ),
                const SizedBox(width: 16),
                StyledButton(
                  child : const Text('Friend Requests'),
                  onPressed : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FriendRequestScreen())
                    );
                    },
                ),
              ]
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
        ]
    );
  }
}

// ensure that friend that you are sending request to exists
void verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
    ) async {
  try {
    var methods =
    await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    if (!methods.contains('password')) {
      errorCallback(FirebaseAuthException(
          code:'invalid-email',
          message: 'This email is does not currently belong to a user account.'));
    }
  } on FirebaseAuthException catch (e) {
    errorCallback(e);
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
                child: FriendForm(),

              ),
            ],
          ),
        ),
    );
  }
}

// Form for finding your friend
class FriendForm extends StatefulWidget {
  const FriendForm({Key? key}) : super(key: key);

  @override
  _FriendFormState createState() => _FriendFormState();
}

class _FriendFormState extends State<FriendForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();


  // for if email doesn't exist
  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 24),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '${(e as dynamic).message}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            StyledButton(
              onPressed: () {
                Navigator.of(context).pop();
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
              Padding( //Next button
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 30),
                child: StyledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) { // make sure not empty
                      verifyEmail( // make sure this email exists
                          _controller.text,
                              (e) => _showErrorDialog(context, 'Invalid email', e),
                      );
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
}

// Page for friend requests
class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

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