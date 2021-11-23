import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'src/authentication.dart';
import 'src/recorder.dart';
import 'src/capsules.dart';
import 'src/contacts.dart';
import 'src/playback.dart';
import 'src/widgets.dart';
import 'src/profile.dart';
import 'dart:collection';
import 'src/utils.dart';

// Current user's contacts
LinkedHashMap<String, String> currentUserContacts = LinkedHashMap<String, String>();

// Login functions
class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();
    _loginState = ApplicationLoginState.loggedOut;
  }

  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get loginState => _loginState;

  String? _email;
  String? get email => _email;

  void startLoginFlow(bool signup) {
    print(signup);
    if(signup == false){
      _loginState = ApplicationLoginState.emailAddress;
    } else{
      _loginState = ApplicationLoginState.register;
    }
    notifyListeners();
  }

  void verifyEmail(
      String email,
      void Function(FirebaseAuthException e) errorCallback,
      ) async {
    try {
      var methods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        errorCallback(FirebaseAuthException(
          code:'invalid-email',
          message: 'This email is does not currently belong to a user account.'));
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  // Fetch contacts for given userID from database
  void populateUserContacts(String userID) {
    currentUserContacts.clear();
    currentUserContacts["Myself"] = firebaseUser!.uid;
    currentUserContacts["Robert"] = "1";
    currentUserContacts["Thomas"] = "2";
    currentUserContacts["Vivianne"] = "3";
  }

  // Sets user reference, name, and email globals in authentication.dart
  Future setUserInformation(void Function(FirebaseAuthException e) errorCallback) async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection("users").doc(firebaseUser!.uid).get().then((queryResult) {
        final Map<String, dynamic> map = queryResult.data()!;
        myName = map['name'];
        myEmail = map['email'];
      });
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
      return e.message;
    }
  }

  Future signInWithEmailAndPassword(
      String email,
      String password,
      void Function(FirebaseAuthException e) errorCallback,
      void Function(FirebaseAuthException e) userInfoErrorCallback,
    ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((value) {
        // Get user information from database
        setUserInformation(userInfoErrorCallback);
        firebaseUser = FirebaseAuth.instance.currentUser;
        // Todo: fetch user contacts from database and populate contacts map with <User name, UserID> key-values
        populateUserContacts(firebaseUser!.uid);
      });
      // Hack so that LoginCard is in loggedOut state next time signOut() is called
      _loginState = ApplicationLoginState.loggedOut;
      return null;
    } on FirebaseAuthException catch (e) {
      if(e.code == 'wrong-password') {
        print(e.message);
      }
      errorCallback(e);
      return e.message;
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  void cancelLogin() {
    _loginState = ApplicationLoginState.loggedOut;
    notifyListeners();
  }

  // Creates new accounts using the provided email, desired display name,
  // and password, as well as sets up the Cloud Firestore fields for
  // them.
  Future registerAccount(String email, String displayName, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password).then((value) {
        // For new user, manually set user information globals
        firebaseUser = FirebaseAuth.instance.currentUser;
        myName = displayName;
        myEmail = email;
        populateUserContacts(firebaseUser!.uid);

        // Create entries in Cloud Firestore for a fresh entry
        CollectionReference all_users = FirebaseFirestore.instance.collection('users');

        // Initializes the contacts, requests, and uid fields for a new account
        all_users.doc(firebaseUser!.uid).set({
          'name': myName!,
          'contacts': {},
          'email': firebaseUser!.email,
          'requests': {},
          'uid': firebaseUser!.uid,
        });

        // Initializes the capsule listings for new users
        all_users.doc(firebaseUser!.uid)
            .collection('capsules')
            .doc('pending_capsules')
            .set({});

        all_users.doc(firebaseUser!.uid)
            .collection('capsules')
            .doc('sent_capsules')
            .set({});
      });

      // Adds user to the master list of all_users for the friend feature
      CollectionReference add_friends = FirebaseFirestore.instance
          .collection('add_friends');

      add_friends.doc('all_users').set({
        '${firebaseUser!.email}' : {'${displayName}' : firebaseUser!.uid,},
      }, SetOptions(merge: true));
      // todo check that email is valid (ie not already in use by another account), erroneously transfers to home card after failed registration
      _loginState = ApplicationLoginState.loggedOut;
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
      return e.message;
    }
  }

  void signOut() {
    //_loginState = ApplicationLoginState.loggedOut;
    // notifyListeners();
    currentUserContacts.clear();
    FirebaseAuth.instance.signOut();
  }

  // Navigates to HomeCard, when login successful
  void navToHome(BuildContext context) {
    // print(_loginState);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeCard()),
    );
  }
}

// Main function
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => App(),
    ),
  );
}

// App opens on LoginCard
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Capsule Login',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
          highlightColor: Colors.deepPurple,
        ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginCard(),

    );
  }
}

// Login definition
class LoginCard extends StatelessWidget {
  const LoginCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Voice Capsule'),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Consumer<ApplicationState>(
          builder: (context, appState, _) => Authentication(
            email: appState.email,
            loginState: appState.loginState,
            startLoginFlow: appState.startLoginFlow,
            verifyEmail: appState.verifyEmail,
            signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
            cancelRegistration: appState.cancelRegistration,
            registerAccount: appState.registerAccount,
            signOut: appState.signOut,
            navToHome: appState.navToHome,
            cancelLogin: appState.cancelLogin,
          ),
        ),
      ),
    );
  }
}

// Home definition
// Ricardo on 11/6: made this Stateful to be able to handle navBar
class HomeCard extends StatefulWidget {
  const HomeCard({Key? key}) : super(key: key);

  @override
  _HomeCardState createState() => _HomeCardState();
}

// Changing Home Card based on navBar
class _HomeCardState extends State<HomeCard>{
  int _currentIndex = 0; // initial index of bottom nav
  final List _children = [
    const RecordWidget(),
    const CapsulesSlide(),
    const ContactsSlide(),
    const ProfileSlide()
  ]; // list of widgets to be displayed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          //'Voice Capsule',
          'User ID: ${firebaseUser!.uid}',
          textScaleFactor: 0.75,
        ),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body:  _children[_currentIndex], // Selected widget will be shown
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // keeps color fixed
        onTap: onTabTapped, // function for switching tabs
        currentIndex: _currentIndex, // index of currently selected tab
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Capsules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_rounded),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        backgroundColor: Colors.grey[200],
        selectedItemColor: Colors.purple,
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

// Recording Screen slide
// Ricardo on 11/6: Part of the change of making LoginCard stateful
class RecordWidget extends StatelessWidget {
  const RecordWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Widget defined in recorder.dart
            SimpleRecorder(contacts: currentUserContacts),
          ],
        ),
      ),
    );
  }
}
