import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'src/authentication.dart';
import 'src/recorder.dart';
import 'src/playback.dart';
import 'src/widgets.dart';

// Info for currently signed in user
User? firebase_user;

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

  Future signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
    ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((value) {
        firebase_user = FirebaseAuth.instance.currentUser;
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

  // changed to authenticate new accounts modeled after signIn
  Future registerAccount(String email, String displayName, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password).then((value) {
        firebase_user = FirebaseAuth.instance.currentUser;
      });
      await credential.user!.updateDisplayName(displayName);
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
  static int _currentIndex = 0; // initial index of bottom nav
  final List _children = [
    const RecordWidget(),
    const CapsulesWidget(),
  ]; // list of widgets to be displayed
  static int _numCapsules = 1; // set at one for now until we figure out multiple notes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voice Capsule Test',
          //'User ID: ${firebase_user?.uid ?? 'none'}',
          //textScaleFactor: 0.75,
        ),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body:  _children[_currentIndex], // Selected widget will be shown
      bottomNavigationBar: BottomNavigationBar(
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
// Ricardo on 11/6: Part of the change of making LoginCard stateless
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
            SimpleRecorder(contacts: <String>['Myself','Contact 1','Contact 2','Contact 3']),
            OutlinedButton(
              child: const Text('LOGOUT'),
              onPressed: () {
                // Logout, then switch back to login page
                ApplicationState().signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginCard()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Capsules Slide
// Ricardo on 11/6: Part of the change of making LoginCard stateless
class CapsulesWidget extends StatelessWidget {
  const CapsulesWidget({Key? key}) : super(key: key);
  // TODO: replace hardcoded audio file with list of recordings
  final String audioFileUrl = 'recorded_file.mp4';
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListWheelScrollView(
        itemExtent: 280,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color : Colors.purple,
              borderRadius : BorderRadius.circular(15),
            ),
            child: SimplePlayback(audioFileUrl: audioFileUrl),
          ),
          Container(
              height: 100,
              decoration: BoxDecoration(
              color : Colors.purple,
              borderRadius : BorderRadius.circular(15),
            ),
            child: const Center(
              child : Text('Capsule 2',
                textAlign : TextAlign.center,
                style : TextStyle(
                  color : Colors.white,
                  fontSize : 50.0,
                )
              )
            )
          ),
        ]
      )
    );
  }
}
