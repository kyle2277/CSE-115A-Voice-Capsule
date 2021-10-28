import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

// Login functions
class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();
    _loginState = ApplicationLoginState.loggedOut;
    // FirebaseAuth.instance.userChanges().listen((user) {
    //   if (user != null) {
    //     _loginState = ApplicationLoginState.loggedIn;
    //   } else {
    //     _loginState = ApplicationLoginState.loggedOut;
    //   }
    //   notifyListeners();
    // });
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
      );
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

  void registerAccount(String email, String displayName, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateProfile(displayName: displayName);
      // Hack so that LoginCard is in loggedOut state next time signOut() is called
      // todo check that email is valid (ie not already in use by another account), erroneously transfers to home card after failed registration
      _loginState = ApplicationLoginState.loggedOut;
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
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
        title: Text('Login to Voice Capsule'),
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
class HomeCard extends StatelessWidget {
  const HomeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Capsule Test'),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: OutlinedButton(
          child: Text('LOGOUT'),
          onPressed: () {
            // Logout, then switch back to login page
            ApplicationState().signOut();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginCard()));
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
}